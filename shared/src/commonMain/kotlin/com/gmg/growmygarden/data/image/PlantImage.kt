package com.gmg.growmygarden.data.image

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@OptIn(ExperimentalUuidApi::class)
class PlantImage(
    val uuid: Uuid = Uuid.random(),
    val imageBytes: ByteArray? = null,
) {
    val hqPath: String
        get() = "/img/$uuid.png"
    val lqPath: String
        get() = "/img/${uuid}_lq.png"
}

@OptIn(ExperimentalEncodingApi::class, ExperimentalUuidApi::class)
object PlantImageSerializer : KSerializer<PlantImage> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("org.gmg.growmygardner.PlantImage", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: PlantImage) {
        val base64Data = value.imageBytes?.let { Base64.encode(it) } ?: ""
        encoder.encodeString("${value.uuid.toHexDashString()}|$base64Data")
    }

    override fun deserialize(decoder: Decoder): PlantImage {
        val str = decoder.decodeString()
        val parts = str.split("|", limit = 2)
        val uuid = Uuid.parse(parts[0])
        val imageBytes = if (parts.size > 1 && parts[1].isNotEmpty()) {
            try {
                Base64.decode(parts[1])
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }
        return PlantImage(uuid, imageBytes)
    }
}
