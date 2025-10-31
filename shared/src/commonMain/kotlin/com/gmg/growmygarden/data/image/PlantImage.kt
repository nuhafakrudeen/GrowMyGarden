package com.gmg.growmygarden.data.image

import io.github.vinceglb.filekit.PlatformFile
import kotlinx.io.files.Path
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlin.uuid.Uuid

class PlantImage(
    val uuid: Uuid = Uuid.Companion.random()
) {
    val hqPath : String
        get() = "/img/$uuid.png"
    val lqPath : String
        get() = "/img/${uuid}_lq.png"
}

object PlantImageSerializer : KSerializer<PlantImage> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("org.gmg.growmygardner.PlantImage", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: PlantImage) {
        encoder.encodeString(
            value.uuid.toHexDashString()
        )
    }

    override fun deserialize(decoder: Decoder): PlantImage {
        return PlantImage(Uuid.parse(decoder.decodeString()))
    }
}

