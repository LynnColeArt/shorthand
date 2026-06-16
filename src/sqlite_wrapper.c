#include <sqlite3.h>
#include <stddef.h>

void *short_sqlite_open_memory(void) {
    sqlite3 *db = NULL;
    if (sqlite3_open(":memory:", &db) != SQLITE_OK) {
        if (db != NULL) {
            sqlite3_close(db);
        }
        return NULL;
    }
    return db;
}

void short_sqlite_close(void *db) {
    if (db != NULL) {
        sqlite3_close((sqlite3 *)db);
    }
}

int short_sqlite_exec(void *db, const char *sql) {
    return sqlite3_exec((sqlite3 *)db, sql, NULL, NULL, NULL);
}

void *short_sqlite_prepare(void *db, const char *sql, int n_byte) {
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3 *)db, sql, n_byte, &stmt, NULL) != SQLITE_OK) {
        if (stmt != NULL) {
            sqlite3_finalize(stmt);
        }
        return NULL;
    }
    return stmt;
}

int short_sqlite_finalize(void *stmt) {
    return sqlite3_finalize((sqlite3_stmt *)stmt);
}

int short_sqlite_bind_parameter_count(void *stmt) {
    return sqlite3_bind_parameter_count((sqlite3_stmt *)stmt);
}

int short_sqlite_bind_null(void *stmt, int index) {
    return sqlite3_bind_null((sqlite3_stmt *)stmt, index);
}

int short_sqlite_bind_int64(void *stmt, int index, long long value) {
    return sqlite3_bind_int64((sqlite3_stmt *)stmt, index, (sqlite3_int64)value);
}

int short_sqlite_bind_double(void *stmt, int index, double value) {
    return sqlite3_bind_double((sqlite3_stmt *)stmt, index, value);
}

int short_sqlite_bind_text(void *stmt, int index, const char *value, int length) {
    return sqlite3_bind_text((sqlite3_stmt *)stmt, index, value, length, SQLITE_TRANSIENT);
}

int short_sqlite_step(void *stmt) {
    return sqlite3_step((sqlite3_stmt *)stmt);
}

int short_sqlite_column_count(void *stmt) {
    return sqlite3_column_count((sqlite3_stmt *)stmt);
}

int short_sqlite_column_type(void *stmt, int index) {
    return sqlite3_column_type((sqlite3_stmt *)stmt, index);
}

long long short_sqlite_column_int64(void *stmt, int index) {
    return sqlite3_column_int64((sqlite3_stmt *)stmt, index);
}

double short_sqlite_column_double(void *stmt, int index) {
    return sqlite3_column_double((sqlite3_stmt *)stmt, index);
}

const unsigned char *short_sqlite_column_text(void *stmt, int index) {
    return sqlite3_column_text((sqlite3_stmt *)stmt, index);
}

int short_sqlite_column_bytes(void *stmt, int index) {
    return sqlite3_column_bytes((sqlite3_stmt *)stmt, index);
}

const char *short_sqlite_column_name(void *stmt, int index) {
    return sqlite3_column_name((sqlite3_stmt *)stmt, index);
}
