package com.example.GatewayDemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;


@SpringBootApplication
@EnableEurekaClient
@CrossOrigin(origins = "*")
public class GatewayDemoApplication {

        public static void main(String[] args) {
                SpringApplication.run(GatewayDemoApplication.class, args);
        }

        
        /* 
        @Bean
        public RouteLocator myRoutes(RouteLocatorBuilder builder) {

                String demoAPI = "http://DemoAPI:8080";

                return builder.routes()
                                // ----------------------------------------------------------------------------------------------------------------USER
                                // API - GET METHODS
                                .route(p -> p
                                                .path("/test").and().method("POST")
                                                .filters(f -> f.setPath("/test/post"))
                                                .uri(demoAPI))
                                .route(p -> p
                                                .path("/test").and().method("GET")
                                                .filters(f -> f.setPath("/test/get"))
                                                .uri(demoAPI))
                                .route(p -> p
                                                .path("/test").and().method("DELETE")
                                                .filters(f -> f.setPath("/test/delete"))
                                                .uri(demoAPI))
                                .route(p -> p
                                                .path("/test").and().method("PUT")
                                                .filters(f -> f.setPath("/test/put"))
                                                .uri(demoAPI))
                                .route(p -> p
                                                .path("/test").and().method("PATCH")
                                                .filters(f -> f.setPath("/test/patch"))
                                                .uri(demoAPI))
                                .build();
        }*/

}

// .route(p -> p
// .path("/h").and().method("GET")
// .filters(f -> f.setPath("/health"))
// .uri(userAPI))
// .route(p -> p
// .path("/a").and().method("GET")
// .filters(f -> f.setPath("/admin"))
// .uri(userAPI))
// .route(p -> p
// .path("/log/*/*").and().method("POST")
// .filters(f ->
// f.rewritePath("/log/(?<UNAME>.*)/(?<PASS>.*)","/g/log/${UNAME}/${PASS}"))
// .uri(userAPI))
// .route(p -> p
// .path("/update/*/*/*/*/*").and().method("POST")
// .filters(f ->
// f.rewritePath("/update/(?<UserID>.*)/(?<NAME>.*)/(?<EMAIL>.*)/(?<AGE>.*)/(?<DOCID>.*)","/user/${UserID}/${NAME}/${EMAIL}/${AGE}/${DOCID}"))
// .uri(userAPI))
//
