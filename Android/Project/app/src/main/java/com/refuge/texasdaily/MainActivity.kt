package com.refuge.texasdaily

import android.Manifest
import android.graphics.Color as AndroidColor
import android.os.Build
import android.os.Bundle
import androidx.activity.SystemBarStyle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.material3.Surface
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.refuge.texasdaily.ui.screens.MainScreen
import com.refuge.texasdaily.ui.screens.OnboardingScreen
import com.refuge.texasdaily.ui.screens.SettingsScreen
import com.refuge.texasdaily.ui.theme.TexasDailyTheme
import com.refuge.texasdaily.viewmodel.TexasViewModel

class MainActivity : ComponentActivity() {

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { /* permission result handled silently */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
        setContent {
            val vm: TexasViewModel = viewModel(factory = TexasViewModel.Factory(applicationContext))
            val isDark by vm.isDarkMode.collectAsState()
            val onboardingDone by vm.onboardingDone.collectAsState()
            var showSettings by remember { mutableStateOf(false) }

            SideEffect {
                enableEdgeToEdge(
                    statusBarStyle = if (isDark) {
                        SystemBarStyle.dark(AndroidColor.TRANSPARENT)
                    } else {
                        SystemBarStyle.light(AndroidColor.TRANSPARENT, AndroidColor.TRANSPARENT)
                    },
                    navigationBarStyle = if (isDark) {
                        SystemBarStyle.dark(AndroidColor.TRANSPARENT)
                    } else {
                        SystemBarStyle.light(AndroidColor.TRANSPARENT, AndroidColor.TRANSPARENT)
                    }
                )
            }

            TexasDailyTheme(darkTheme = isDark) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .systemBarsPadding()
                ) {
                    AnimatedContent(targetState = onboardingDone to showSettings, label = "screen") { (done, inSettings) ->
                        when {
                            !done -> OnboardingScreen(
                                onFinished = { vm.completeOnboarding() }
                            )
                            inSettings -> SettingsScreen(
                                viewModel = vm,
                                onClose = { showSettings = false }
                            )
                            else -> MainScreen(
                                viewModel = vm,
                                onOpenSettings = { showSettings = true }
                            )
                        }
                    }
                }
            }
        }
    }
}
