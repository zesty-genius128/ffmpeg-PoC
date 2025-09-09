import { NativeModulesProxy } from 'expo-modules-core';

import { FFmpegMergeModule } from './FFmpegMerge.types';

// It loads the native module object from the JSI or falls back to
// the bridge module (from NativeModulesProxy) if the remote debugger is on.
export default NativeModulesProxy.FFmpegMerge as FFmpegMergeModule;