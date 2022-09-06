package com.example.kotlinwebrtc.model

import lombok.Getter
import lombok.Setter


data class Ice(
    val candidate: String,
    val sdpMid: String,
    val sdpMLineIndex: Int
)
