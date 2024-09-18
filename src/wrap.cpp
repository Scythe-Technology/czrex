#include <vector>
#include <regex>
#include <string>
#include <iterator>

extern "C" struct match {
    const char** strings;
    size_t* positions;
    size_t groups;
};

extern "C" std::regex* zig_regex_new(const char* cstr, size_t len, int flags) {
    std::string pattern(cstr, len);
    try {
        if (flags != -1)
            return new std::regex(pattern, (std::regex::flag_type)flags);
        return new std::regex(pattern);
    } catch (std::regex_error& e) {
        return nullptr;
    }
}

extern "C" bool zig_regex_match(std::regex* r, const char* cstr, size_t len) {
    std::smatch match;
    std::string text(cstr, len);
    return std::regex_match(text, *r);
}

extern "C" match zig_regex_captured_match(std::regex* r, const char* cstr, size_t len) {
    std::smatch match;
    std::string text(cstr, len);
    std::regex_match(text, match, *r);

    size_t groups = match.size();
    const char** c_strings = new const char*[groups];
    size_t* g_positions = new size_t[groups];
  
    for (size_t j = 0; j < match.size(); ++j) {
        c_strings[j] = strdup(match.str(j).c_str());
        g_positions[j] = match.position(j);
    }

    return { c_strings, g_positions, groups};
}

extern "C" match zig_regex_search(std::regex* r, const char* cstr, size_t len) {
    std::smatch match;
    std::string text(cstr, len);
    std::regex_search(text, match, *r);

    size_t groups = match.size();
    const char** c_strings = new const char*[groups];
    size_t* g_positions = new size_t[groups];
  
    for (size_t j = 0; j < match.size(); ++j) {
        c_strings[j] = strdup(match.str(j).c_str());
        g_positions[j] = match.position(j);
    }

    return { c_strings, g_positions, groups};
}

extern "C" const char* zig_regex_replace(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format, std::regex_constants::format_first_only);

    return strdup(result.c_str());;
}

extern "C" const char* zig_regex_replaceAll(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format);

    return strdup(result.c_str());;
}

extern "C" const char* zig_regex_format(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format, std::regex_constants::format_no_copy);

    return strdup(result.c_str());;
}

extern "C" void zig_regex_free(std::regex* r) {
    delete r;
}

extern "C" void zig_regex_free_mem(void* ptr) {
    free(ptr);
}

extern "C" void zig_regex_free_match(match m) {
    for (size_t i = 0; i < m.groups; ++i)
        free((void*)m.strings[i]);
    delete[] m.positions;
    delete[] m.strings;
}