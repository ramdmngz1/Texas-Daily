package com.refuge.texasdaily.ui.screens

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.refuge.texasdaily.ui.theme.AccentGreen
import kotlinx.coroutines.launch
import kotlin.math.cos
import kotlin.math.sin

private data class OnboardingPage(
    val icon: ImageVector?,
    val title: String,
    val description: String,
    val usePointedStar: Boolean = false
)

private val pages = listOf(
    OnboardingPage(
        icon = null,
        usePointedStar = true,
        title = "Welcome to Texas Daily",
        description = "Discover something new about the Lone Star State every single day — from its rich history to its wide-open landscapes."
    ),
    OnboardingPage(
        icon = Icons.Default.MenuBook,
        usePointedStar = false,
        title = "700+ Curated Facts",
        description = "Explore verified facts across History, Geography, Culture, Sports, Science, and more — all about Texas."
    ),
    OnboardingPage(
        icon = Icons.Default.Search,
        title = "Browse by Category",
        description = "Filter facts by topic so you always see what interests you most. Tap the filter icon anytime to change it."
    ),
    OnboardingPage(
        icon = Icons.Default.Notifications,
        title = "Never Miss a Day",
        description = "Turn on daily reminders in Settings to get a nudge at the time that works best for you."
    )
)

@Composable
fun OnboardingScreen(onFinished: () -> Unit) {
    val pagerState = rememberPagerState { pages.size }
    val scope = rememberCoroutineScope()
    val isLastPage = pagerState.currentPage == pages.lastIndex

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Skip button row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 16.dp),
            horizontalArrangement = Arrangement.End
        ) {
            if (!isLastPage) {
                TextButton(onClick = onFinished) {
                    Text(
                        "Skip",
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        // Pager
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f)
        ) { index ->
            PageContent(page = pages[index])
        }

        // Dot indicators
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(bottom = 24.dp)
        ) {
            repeat(pages.size) { index ->
                val isSelected = index == pagerState.currentPage
                val width by animateDpAsState(
                    targetValue = if (isSelected) 24.dp else 8.dp,
                    label = "dot_width"
                )
                Box(
                    modifier = Modifier
                        .height(8.dp)
                        .width(width)
                        .clip(CircleShape)
                        .background(
                            if (isSelected) AccentGreen
                            else MaterialTheme.colorScheme.onBackground.copy(alpha = 0.2f)
                        )
                )
            }
        }

        // Action button
        Button(
            onClick = {
                if (isLastPage) {
                    onFinished()
                } else {
                    scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                }
            },
            colors = ButtonDefaults.buttonColors(containerColor = AccentGreen),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
        ) {
            Text(
                text = if (isLastPage) "Get Started" else "Next",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold
            )
        }

        Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun PageContent(page: OnboardingPage) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .size(128.dp)
                .clip(CircleShape)
                .background(AccentGreen.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            if (page.usePointedStar) {
                val starColor = AccentGreen
                Canvas(modifier = Modifier.size(68.dp)) {
                    val cx = size.width / 2f
                    val cy = size.height / 2f
                    val outer = size.width / 2f
                    val inner = outer * 0.40f
                    val path = Path()
                    for (i in 0 until 10) {
                        val angle = Math.toRadians(i * 36.0 - 90.0).toFloat()
                        val r = if (i % 2 == 0) outer else inner
                        val x = cx + r * cos(angle)
                        val y = cy + r * sin(angle)
                        if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
                    }
                    path.close()
                    drawPath(path = path, color = starColor, style = Fill)
                }
            } else {
                Icon(
                    imageVector = page.icon!!,
                    contentDescription = null,
                    tint = AccentGreen,
                    modifier = Modifier.size(56.dp)
                )
            }
        }

        Spacer(Modifier.height(40.dp))

        Text(
            text = page.title,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onBackground
        )

        Spacer(Modifier.height(16.dp))

        Text(
            text = page.description,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.72f),
            lineHeight = MaterialTheme.typography.bodyLarge.lineHeight
        )
    }
}
