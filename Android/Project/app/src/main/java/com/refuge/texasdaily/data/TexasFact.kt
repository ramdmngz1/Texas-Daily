package com.refuge.texasdaily.data

import com.google.gson.annotations.SerializedName

data class TexasFact(
    val id: Int,
    val fact: String,
    val category: String,
    val date: String?,
    val background: String,
    val source: String
)

data class FactsWrapper(
    @SerializedName("facts") val facts: List<TexasFact>
)
