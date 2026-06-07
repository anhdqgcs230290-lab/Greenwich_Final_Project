// mobile-app/app/index.tsx
import React from 'react';
import { StyleSheet, View } from 'react-native';
import ReportScreen from './ReportScreen';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <ReportScreen />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
});