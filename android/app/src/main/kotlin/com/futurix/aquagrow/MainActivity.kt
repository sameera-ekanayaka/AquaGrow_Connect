package com.futurix.aquagrow

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity: local_auth shows the system
// biometric prompt, which needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
