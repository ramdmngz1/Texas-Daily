package com.refuge.texasdaily.ui.screens

import android.content.Intent
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.refuge.texasdaily.ui.components.BannerAdView
import com.refuge.texasdaily.ui.components.CategoryFilterSheet
import com.refuge.texasdaily.ui.theme.AccentGreen
import com.refuge.texasdaily.ui.theme.LightChip
import com.refuge.texasdaily.viewmodel.TexasViewModel

@Composable
fun MainScreen(
    viewModel: TexasViewModel,
    onOpenSettings: () -> Unit
) {
    val context = LocalContext.current
    val fact by viewModel.currentFact.collectAsState()
    val selectedCategories by viewModel.selectedCategories.collectAsState()
    val allCategories by viewModel.allCategories.collectAsState()
    val adsRemoved by viewModel.billingManager.adsRemoved.collectAsState()

    var showFilter by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = if (adsRemoved) 0.dp else 50.dp)
        ) {
            // Top bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onOpenSettings) {
                    Icon(
                        Icons.Default.Settings,
                        contentDescription = "Settings",
                        tint = MaterialTheme.colorScheme.onBackground
                    )
                }
                Text(
                    "TEXAS DAILY",
                    style = MaterialTheme.typography.labelLarge,
                    color = AccentGreen
                )
                Row {
                    fact?.let { currentFact ->
                        IconButton(onClick = {
                            val shareText = "${currentFact.fact}\n\nSource: ${currentFact.source}\n\nShared from Texas Daily"
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, shareText)
                            }
                            context.startActivity(Intent.createChooser(intent, "Share fact"))
                        }) {
                            Icon(
                                Icons.Default.Share,
                                contentDescription = "Share fact",
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                        }
                    }
                    IconButton(onClick = { showFilter = true }) {
                        Icon(
                            Icons.Default.FilterList,
                            contentDescription = "Filter categories",
                            tint = if (selectedCategories.isNotEmpty()) AccentGreen
                                   else MaterialTheme.colorScheme.onBackground
                        )
                    }
                }
            }

            // Fact card
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                fact?.let { currentFact ->
                    // Category chip
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = LightChip,
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    ) {
                        Text(
                            currentFact.category,
                            style = MaterialTheme.typography.labelMedium,
                            color = AccentGreen,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp)
                        )
                    }

                    // Main fact card
                    Card(
                        shape = RoundedCornerShape(20.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            currentFact.fact,
                            style = MaterialTheme.typography.headlineMedium,
                            textAlign = TextAlign.Start,
                            modifier = Modifier.padding(24.dp)
                        )
                    }

                    // Background info card
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(20.dp)) {
                            Text(
                                "Background",
                                style = MaterialTheme.typography.labelLarge,
                                color = AccentGreen
                            )
                            Spacer(Modifier.height(8.dp))
                            Text(
                                currentFact.background,
                                style = MaterialTheme.typography.bodyLarge
                            )
                        }
                    }

                    // Source & date
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            "Source: ${currentFact.source}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                            textAlign = TextAlign.Center
                        )
                        currentFact.date?.let { date ->
                            Text(
                                date,
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.4f)
                            )
                        }
                    }
                }

                // Refresh button
                Button(
                    onClick = { viewModel.loadNewFact() },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentGreen),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                ) {
                    Text(
                        "New Random Texas Fact",
                        style = MaterialTheme.typography.labelLarge,
                        color = Color.White
                    )
                }

                Spacer(Modifier.height(8.dp))
            }
        }

        // Banner ad at bottom
        if (!adsRemoved) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .height(50.dp)
                    .background(MaterialTheme.colorScheme.background)
            ) {
                BannerAdView()
            }
        }
    }

    if (showFilter) {
        CategoryFilterSheet(
            categories = allCategories,
            selected = selectedCategories,
            onToggle = { viewModel.toggleCategory(it) },
            onClear = { viewModel.clearCategoryFilter() },
            onDismiss = { showFilter = false }
        )
    }
}
