import React, {useRef, useEffect} from 'react';
import {AppState, SafeAreaView, StyleSheet} from 'react-native';
import {WebView} from 'react-native-webview';

function App(): React.JSX.Element {
  const appState = useRef(AppState.currentState);
  const webViewRef = useRef(null);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (
        appState.current.match(/inactive|background/) &&
        nextAppState === 'active'
      ) {
        // フォアグラウンドに戻ったときの処理
        if (webViewRef.current) {
          webViewRef.current.reload();
        }
      }
      appState.current = nextAppState;
    });

    return () => subscription.remove();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <WebView
        source={{uri: 'https://nanitabe.kibotsu.com/calender/week/thisweek'}}
        ref={webViewRef}
        style={{flex: 1}}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export default App;
