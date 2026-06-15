package com.waqt.api.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Expose the uploads directory to serve uploaded images statically
        String uploadDir = "uploads/posts/";
        File file = new File(uploadDir);
        if (!file.exists()) {
            file.mkdirs();
        }
        
        registry.addResourceHandler("/uploads/posts/**")
                .addResourceLocations("file:" + file.getAbsolutePath() + "/");
    }
}
