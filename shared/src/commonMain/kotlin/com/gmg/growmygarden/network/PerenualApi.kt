package com.gmg.growmygarden.network

import com.gmg.growmygarden.data.source.PlantInfo
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsBytes
import kotlinx.serialization.Serializable

@Serializable
data class PerenualListResponse<T>(val data: List<T>)

class PerenualApi(
    private val client: HttpClient,
    private val apiKey: String,
) {

    /**
     * Search for plants by name/query string.
     * Returns a list of matching PlantInfo objects.
     */
    suspend fun searchPerenualAPI(query: String): List<PlantInfo> {
        val pulledPlantInfo: PerenualListResponse<PlantInfo> = client.get("species-list") {
            url.parameters.append("q", query)
            url.parameters.append("key", apiKey)
        }.body()

        return pulledPlantInfo.data
    }

    /**
     * Get detailed plant info by Perenual ID.
     */
    suspend fun searchPlantInPerenualAPI(id: Int): PlantInfo {
        return client.get("species/details/$id") {
            url.parameters.append("key", apiKey)
        }.body()
    }

    /**
     * Search for a plant by species name and return the first match.
     * This is useful for auto-populating plant data when a user enters a species.
     */
    suspend fun searchPlantBySpecies(speciesName: String): PlantInfo? {
        return try {
            val results = searchPerenualAPI(speciesName)
            // Find exact match first, then fallback to first result
            results.firstOrNull { info ->
                info.name?.equals(speciesName, ignoreCase = true) == true ||
                    info.scientificName?.any { it.equals(speciesName, ignoreCase = true) } == true
            } ?: results.firstOrNull()
        } catch (e: Exception) {
            println("Error searching for species '$speciesName': ${e.message}")
            null
        }
    }

    /**
     * Download image bytes from a URL.
     * Returns null if the download fails.
     */
    suspend fun downloadImageFromUrl(imageUrl: String): ByteArray? {
        return try {
            client.get(imageUrl).bodyAsBytes()
        } catch (e: Exception) {
            println("Error downloading image from '$imageUrl': ${e.message}")
            null
        }
    }

    /**
     * Get the best available image URL from PlantInfo.
     * Prefers medium > regular > small > thumbnail > original
     */
    fun getBestImageUrl(plantInfo: PlantInfo): String? {
        val image = plantInfo.image ?: return null
        return image.mediumUrl
            ?: image.regularUrl
            ?: image.smallUrl
            ?: image.thumbnail
            ?: image.originalUrl
    }

    /**
     * Search for a plant by species and download its image.
     * Returns a pair of (PlantInfo, ByteArray?) where ByteArray is the image data.
     */
    suspend fun searchPlantAndGetImage(speciesName: String): Pair<PlantInfo?, ByteArray?> {
        val plantInfo = searchPlantBySpecies(speciesName) ?: return null to null
        val imageUrl = getBestImageUrl(plantInfo) ?: return plantInfo to null
        val imageBytes = downloadImageFromUrl(imageUrl)
        return plantInfo to imageBytes
    }
}
