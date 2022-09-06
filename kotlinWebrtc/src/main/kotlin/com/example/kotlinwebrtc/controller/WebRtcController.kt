package com.example.kotlinwebrtc.controller

import com.example.kotlinwebrtc.model.Ice
import org.springframework.messaging.handler.annotation.MessageMapping
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.messaging.handler.annotation.SendTo
import org.springframework.web.bind.annotation.RestController

@RestController
class WebRtcController {
    val roomName = "wagly"

    @MessageMapping("/join")
    @SendTo("/topic/wagly/join")
    fun sendMessage(@Payload data: String): String {
        print("소컷연결 성공");
        return "반환데이터";
    }

    @MessageMapping("/offer")
    @SendTo("/topic/wagly/offer")
    fun offer(@Payload data: Any): Any{
        print("offer : $data");
        return data;
    }

    @MessageMapping("/answer")
    @SendTo("/topic/wagly/answer")
    fun answer(@Payload data: Any): Any {
        print("answer : $data");
        return data;
    }

    @MessageMapping("/ice")
    @SendTo("/topic/wagly/ice")
    fun ice(@Payload data: Ice): Ice {
        print("ice : $data");
        return data;
    }

}