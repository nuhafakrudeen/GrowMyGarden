package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.image.PlantScopeProvider
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import io.github.vinceglb.filekit.FileKit
import io.github.vinceglb.filekit.ImageFormat
import io.github.vinceglb.filekit.PlatformFile
import io.github.vinceglb.filekit.compressImage
import io.github.vinceglb.filekit.div
import io.github.vinceglb.filekit.filesDir
import io.github.vinceglb.filekit.readBytes
import io.github.vinceglb.filekit.write
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.receiveAsFlow
import kotlin.time.Duration.Companion.milliseconds

@OptIn(FlowPreview::class)
class PlantImageStore(
    private val scopeProvider: PlantScopeProvider,
) {

    val writeChannel = Channel<Pair<PlantImage, ByteArray>>(Channel.CONFLATED)

    fun saveImage(bytes: ByteArray): PlantImage {
        val img = PlantImage()
        writeChannel.trySend(
            img to bytes,
        )
        return img
    }

    @NativeCoroutines
    suspend fun saveImage(file: PlatformFile): PlantImage {
        val img = PlantImage()
        writeChannel.trySend(
            img to file.readBytes(),
        )
        return img
    }

    init {
        writeChannel.receiveAsFlow()
            .debounce(500.milliseconds)
            .onEach { (image, bytes) ->
                val hqFile: PlatformFile = FileKit.filesDir / image.hqPath
                val lqFile: PlatformFile = FileKit.filesDir / image.lqPath

                hqFile.write(bytes)

                lqFile.write(
                    FileKit.compressImage(
                        hqFile,
                        imageFormat = ImageFormat.PNG,
                        maxWidth = 400,
                        maxHeight = 400,
                    ),
                )
            }.launchIn(scopeProvider.scope)
    }
}
