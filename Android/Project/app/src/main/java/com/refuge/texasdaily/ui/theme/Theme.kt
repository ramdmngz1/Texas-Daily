package com.refuge.texasdaily.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColorScheme = lightColorScheme(
    primary = AccentGreen,
    background = LightBackground,
    surface = LightCard,
    onBackground = LightInk,
    onSurface = LightInk,
    secondary = AccentGreen,
    onPrimary = DarkInk
)

private val DarkColorScheme = darkColorScheme(
    primary = AccentGreen,
    background = DarkBackground,
    surface = DarkCard,
    onBackground = DarkInk,
    onSurface = DarkInk,
    secondary = AccentGreen,
    onPrimary = DarkInk
)

@Composable
fun TexasDailyTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
