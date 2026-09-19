import judgeExecInClientOrServer, {
  ExecSituation,
} from './judgeExecInClientOrServer';

const generateApiOrigin: () => string = () => {
  if (process.env.NEXT_PUBLIC_ENVIRONMENT !== 'development') {
    return process.env.NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN as string;
  }
  switch (judgeExecInClientOrServer) {
    case ExecSituation.ExecInServerSide:
      return 'http://nanitabe_back:18101';
    case ExecSituation.ExecInClientSide:
      return 'http://localhost:18101';
    default:
      return '';
  }
};

export default generateApiOrigin;
