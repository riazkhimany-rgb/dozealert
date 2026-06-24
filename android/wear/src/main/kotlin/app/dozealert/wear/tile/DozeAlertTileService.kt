package app.dozealert.wear.tile

import androidx.wear.protolayout.ColorBuilders
import androidx.wear.protolayout.DimensionBuilders
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.material.Text
import androidx.wear.protolayout.material.Typography
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import app.dozealert.wear.TripState
import app.dozealert.wear.TripStateRepository
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

class DozeAlertTileService : TileService() {
    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val state = TripStateRepository.getInstance(this).state.value
        return Futures.immediateFuture(buildTile(state))
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> {
        return Futures.immediateFuture(
            ResourceBuilders.Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build(),
        )
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

        return TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setTileTimeline(
                TimelineBuilders.Timeline.Builder()
                    .addTimelineEntry(
                        TimelineBuilders.TimelineEntry.Builder()
                            .setLayout(
                                LayoutElementBuilders.Layout.Builder()
                                    .setRoot(content)
                                    .build(),
                            )
                            .build(),
                    )
                    .build(),
            )
            .build()
    }

    companion object {
        private const val RESOURCES_VERSION = "1"
    }
}
