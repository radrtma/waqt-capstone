package com.waqt.api.config.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import java.util.*;

public class HeaderMapRequestWrapper extends HttpServletRequestWrapper {
    private final Map<String, String> headerMap = new HashMap<>();

    public HeaderMapRequestWrapper(HttpServletRequest request) {
        super(request);
    }

    public void addHeader(String name, String value) {
        headerMap.put(name, value);
    }

    @Override
    public String getHeader(String name) {
        // Handle case-insensitive header names
        for (String key : headerMap.keySet()) {
            if (key.equalsIgnoreCase(name)) {
                return headerMap.get(key);
            }
        }
        return super.getHeader(name);
    }

    @Override
    public Enumeration<String> getHeaderNames() {
        List<String> names = Collections.list(super.getHeaderNames());
        names.addAll(headerMap.keySet());
        return Collections.enumeration(names);
    }

    @Override
    public Enumeration<String> getHeaders(String name) {
        List<String> values = new ArrayList<>();
        boolean found = false;
        for (String key : headerMap.keySet()) {
            if (key.equalsIgnoreCase(name)) {
                values.add(headerMap.get(key));
                found = true;
                break;
            }
        }
        if (!found) {
            Enumeration<String> superHeaders = super.getHeaders(name);
            while (superHeaders.hasMoreElements()) {
                values.add(superHeaders.nextElement());
            }
        }
        return Collections.enumeration(values);
    }
}
