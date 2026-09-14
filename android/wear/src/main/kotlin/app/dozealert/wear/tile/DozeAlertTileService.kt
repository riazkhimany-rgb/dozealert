package app.dozealert.wear.tile

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders
import androidx.wear.protolayout.DimensionBuilders
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.material.Text
import androidx.wear.protolayout.material.Typography
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import app.dozealert.wear.SplashActivity
import app.dozealert.wear.TripState
import app.dozealert.wear.TripStateRepository
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.guava.future

class DozeAlertTileService : TileService() {
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        return serviceScope.future {
            val repository = TripStateRepository.getInstance(this@DozeAlertTileService)
            repository.refreshFromPhone()
            buildTile(repository.state.value)
        }
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> {
        return serviceScope.future {
            ResourceBuilders.Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build()
        }
    }

    private fun buildTile(state: TripState): TileBuilders.Tile {
        val title = Text.Builder(this, state.statusLabel)
            .setTypography(Typography.TYPOGRAPHY_CAPTION1)
            .setColor(ColorBuilders.argb(0xFF94A3B8.toInt()))
            .build()

        val line = Text.Builder(this, state.tileLine)
            .setTypography(Typography.TYPOGRAPHY_TITLE3)
            .setColor(ColorBuilders.argb(0xFF4CC9F0.toInt()))
            .setMaxLines(2)
            .build()

        val content = LayoutElementBuilders.Column.Builder()
            .setWidth(DimensionBuilders.expand())
            .addContent(title)
            .addContent(
                LayoutElementBuilders.Spacer.Builder()
                    .setHeight(DimensionBuilders.dp(4f))
                    .build(),
            )
            .addContent(line)
            .build()

        // Wear App Quality: tile canvas must be true black (#000000), and the
        // whole tile must be tappable so the empty state has a way forward (WO-V9).
        val root = LayoutElementBuilders.Box.Builder()
            .setWidth(DimensionBuilders.expand())
            .setHeight(DimensionBuilders.expand())
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setBackground(
                        ModifiersBuilders.Background.Builder()
                            .setColor(ColorBuilders.argb(0xFF000000.toInt()))
                            .build(),
                    )
                    .setClickable(openAppClickable())
                    .build(),
            )
            .addContent(content)
            .build()

        return TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setTileTimeline(
                TimelineBuilders.Timeline.Builder()
                    .addTimelineEntry(
                        TimelineBuilders.TimelineEntry.Builder()
                            .setLayout(
                                LayoutElementBuilders.Layout.Builder()
                                    .setRoot(root)
                                    .build(),
                            )
                            .build(),
                    )
                    .build(),
            )
            .build()
    }

    /**
     * Opens the watch app. Targets [SplashActivity] rather than `MainActivity`
     * because the tile host launches this from another process, so the target
     * must be an exported activity — and routing through the launcher activity
     * also keeps the WO-V15 branded launch on the tile entry path.
     */
    private fun openAppClickable(): ModifiersBuilders.Clickable {
        return ModifiersBuilders.Clickable.Builder()
            .setId(CLICK_ID_OPEN_APP)
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setPackageName(packageName)
                            .setClassName(SplashActivity::class.java.name)
                            .build(),
                    )
                    .build(),
            )
            .build()
    }

    companion object {
        private const val RESOURCES_VERSION = "2"
        private const val CLICK_ID_OPEN_APP = "open_app"
    }
}
