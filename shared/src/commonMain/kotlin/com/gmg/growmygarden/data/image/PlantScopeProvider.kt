package com.gmg.growmygarden.data.image

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlin.coroutines.CoroutineContext

class PlantScopeProvider(
    dispatcher: CoroutineDispatcher = Dispatchers.IO,
    val writeContext: CoroutineContext = CoroutineName("image-write") + dispatcher.limitedParallelism(1),
    val readContext: CoroutineContext = CoroutineName("image-read") + dispatcher,
    val scope: CoroutineScope = CoroutineScope(writeContext),
)
