const next = require('next');
const { IncomingMessage, ServerResponse } = require('http');
const { Duplex } = require('stream');

const app = next({ dev: false });
let _nextJsRequestHandler = null;
async function getNextJsRequestHandler() {
  if (_nextJsRequestHandler) return _nextJsRequestHandler;
  await app.prepare();
  _nextJsRequestHandler = app.getRequestHandler();
  return _nextJsRequestHandler;
}

function convertChunkToBuffer(chunk, encoding) {
  if (typeof chunk === 'string') return Buffer.from(chunk, encoding);
  if (Buffer.isBuffer(chunk)) return chunk;
  if (chunk instanceof Uint8Array) return Buffer.from(chunk);
  if (typeof chunk === 'object') {
    try {
      return Buffer.from(JSON.stringify(chunk), encoding);
    } catch (e) {
      console.warn('Chunk conversion failed:', e);
      return Buffer.alloc(0);
    }
  }
  return null;
}

function createNextJsRequest(event) {
  const req = new IncomingMessage();
  req.method =
    event.httpMethod ||
    (event.requestContext &&
      event.requestContext.http &&
      event.requestContext.http.method) ||
    'GET';
  req.headers = event.headers;
  req.url = event.rawPath;
  req.body = event.body ? Buffer.from(event.body) : Buffer.alloc(0);
  return req;
}

class DummySocket extends Duplex {
  _read(size) {}

  _write(chunk, encoding, callback) {
    callback();
  }

  setTimeout(msecs, callback) {
    if (callback) callback();
  }

  setNoDelay(noDelay) {}

  setKeepAlive(enable, initialDelay) {}

  address() {
    return { address: '127.0.0.1', family: 'IPv4', port: 0 };
  }

  destroy(error) {
    this.push(null);
    this.emit('close', error);
  }
}

function setupResponseCapture(nextJsRequest) {
  const chunks = [];
  const socket = new DummySocket();
  nextJsRequest.socket = socket;
  const res = new ServerResponse(nextJsRequest);
  res.assignSocket(socket);
  const originalWrite = res.write;
  res.write = (chunk, encoding, callback) => {
    const buffer = convertChunkToBuffer(chunk, encoding);
    if (buffer) {
      chunks.push(buffer);
      return originalWrite.call(res, buffer, encoding, callback);
    }
    return originalWrite.call(res, chunk, encoding, callback);
  };
  const originalEnd = res.end;
  res.end = (chunk, encoding, callback) => {
    if (typeof chunk === 'function') {
      callback = chunk;
      chunk = undefined;
      encoding = undefined;
    } else if (typeof encoding === 'function') {
      callback = encoding;
      encoding = undefined;
    }
    if (chunk) {
      const buffer = convertChunkToBuffer(chunk, encoding);
      if (buffer) {
        chunks.push(buffer);
        return originalEnd.call(res, buffer, encoding, callback);
      }
      return originalEnd.call(res, chunk, encoding, callback);
    }
    return originalEnd.call(res, chunk, encoding, callback);
  };
  return { enhancedResponse: res, chunks };
}

async function handleNextJsRequest(nextJsRequest) {
  const { enhancedResponse, chunks } = setupResponseCapture(nextJsRequest);
  const handler = await getNextJsRequestHandler();
  await new Promise((resolve, reject) => {
    enhancedResponse.on('finish', resolve);
    Promise.resolve(handler(nextJsRequest, enhancedResponse)).catch(reject);
  });
  return [enhancedResponse, chunks];
}

async function convertNextJsResponseToLambdaResponse(nextJsResponse, chunks) {
  const headers = { ...nextJsResponse.headers };
  delete headers['content-encoding'];
  delete headers['Content-Encoding'];
  headers['Content-Type'] = 'text/html; charset=utf-8';

  return {
    statusCode: nextJsResponse.statusCode,
    headers,
    body: Buffer.concat(chunks).toString('utf-8'),
    isBase64Encoded: false,
  };
}

exports.handle = async (event, _context) => {
  try {
    const nextJsRequest = createNextJsRequest(event);
    const [nextJsResponse, chunks] = await handleNextJsRequest(nextJsRequest);
    return await convertNextJsResponseToLambdaResponse(nextJsResponse, chunks);
  } catch (error) {
    console.error('Error during SSR processing:', error);
    return {
      statusCode: 500,
      body: `Internal Server Error: ${error.message}\n${error.stack}`,
    };
  }
};

// デバッグ方法
// curl -XPOST "http://localhost:8080/2015-03-31/functions/function/invocations" \
//   -H "Content-Type: application/json" \
//   -d '{
// "rawPath": "/calender/week/thisweek",
//   "httpMethod": "GET",
//   "headers": {
//   "Content-Type": "text/html"
// }
// }'
