package com.waqt.api.entity;

import java.io.Serializable;
import java.util.Objects;

public class UserHistoryId implements Serializable {
    private Long userId;
    private String date;

    public UserHistoryId() {}

    public UserHistoryId(Long userId, String date) {
        this.userId = userId;
        this.date = date;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserHistoryId that = (UserHistoryId) o;
        return Objects.equals(userId, that.userId) && Objects.equals(date, that.date);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, date);
    }
}
