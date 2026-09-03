package com.jetbrains.grade.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

// ── DBConnection.java ─────────────────────────────────────────────────
// Utility class: cung cấp Connection đến SQL Server.
// Dùng mssql-jdbc-12.x.jre11.jar (đặt trong WEB-INF/lib).
// ─────────────────────────────────────────────────────────────────────
public class DBConnection {

    // ── Thông số kết nối ─────────────────────────────────────────────
    private static final String SERVER   = "localhost";   // Máy chủ SQL
    private static final String PORT     = "1433";        // Cổng mặc định
    private static final String DATABASE = "GradeDB";    // Tên database
    private static final String USER     = "sa";          // Tài khoản SQL
    private static final String PASSWORD = "YourPass123!"; // Mật khẩu

    // JDBC URL cho SQL Server:
    // encrypt=false            → tắt TLS (chỉ dùng ở môi trường dev)
    // trustServerCertificate=true → không xác minh cert
    private static final String URL =
            "jdbc:sqlserver://" + SERVER + ":" + PORT
                    + ";databaseName=" + DATABASE
                    + ";encrypt=false;trustServerCertificate=true";

    // static block: chạy 1 lần khi class được nạp vào JVM
    // Nạp JDBC Driver vào JVM để DriverManager nhận ra URL sqlserver://
    static {
        try {
            Class.forName(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(
                    "Không tìm thấy SQL Server JDBC Driver!", e);
        }
    }

    // Trả về 1 Connection mới mỗi lần gọi.
    // DAO dùng try-with-resources để tự đóng connection sau khi xong.
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }}

