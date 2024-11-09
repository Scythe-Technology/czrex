#include <vector>
#include <regex>
#include <string>
#include <iterator>

extern "C" struct match {
    const char** strings;
    size_t* positions;
    size_t groups;
};

extern "C" struct wmatch {
    const wchar_t** strings;
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

extern "C" std::wregex* zig_wregex_new(const wchar_t* cstr, size_t len, int flags) {
    std::wstring pattern(cstr, len);
    try {
        if (flags != -1)
            return new std::wregex(pattern, (std::regex::flag_type)flags);
        return new std::wregex(pattern);
    } catch (std::regex_error& e) {
        return nullptr;
    }
}

extern "C" bool zig_regex_match(std::regex* r, const char* cstr, size_t len) {
    std::string text(cstr, len);
    return std::regex_match(text, *r);
}

extern "C" bool zig_wregex_match(std::wregex* r, const wchar_t* cstr, size_t len) {
    std::wstring text(cstr, len);
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

extern "C" wmatch zig_wregex_captured_match(std::wregex* r, const wchar_t* cstr, size_t len) {
    std::wsmatch match;
    std::wstring text(cstr, len);
    std::regex_match(text, match, *r);

    size_t groups = match.size();
    const wchar_t** c_strings = new const wchar_t*[groups];
    size_t* g_positions = new size_t[groups];
  
    for (size_t j = 0; j < match.size(); ++j) {
        c_strings[j] = wcsdup(match.str(j).c_str());
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

extern "C" wmatch zig_wregex_search(std::wregex* r, const wchar_t* cstr, size_t len) {
    std::wsmatch match;
    std::wstring text(cstr, len);
    std::regex_search(text, match, *r);

    size_t groups = match.size();
    const wchar_t** c_strings = new const wchar_t*[groups];
    size_t* g_positions = new size_t[groups];
  
    for (size_t j = 0; j < match.size(); ++j) {
        c_strings[j] = wcsdup(match.str(j).c_str());
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

extern "C" const wchar_t* zig_wregex_replace(std::wregex* r, const wchar_t* str, size_t strlen, const wchar_t* fmt, size_t fmtlen) {
    std::wstring text(str, strlen);
    std::wstring format(fmt, fmtlen);

    std::wstring result = std::regex_replace(text, *r, format, std::regex_constants::format_first_only);

    return wcsdup(result.c_str());
}

extern "C" const char* zig_regex_replaceAll(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format);

    return strdup(result.c_str());
}

extern "C" const wchar_t* zig_wregex_replaceAll(std::wregex* r, const wchar_t* str, size_t strlen, const wchar_t* fmt, size_t fmtlen) {
    std::wstring text(str, strlen);
    std::wstring format(fmt, fmtlen);

    std::wstring result = std::regex_replace(text, *r, format);

    return wcsdup(result.c_str());
}

extern "C" match* zig_regex_captures(std::regex* r, const char* cstr, size_t len, size_t* out_count, bool global) {
    std::string text(cstr, len);
    std::sregex_iterator begin(text.begin(), text.end(), *r);
    std::sregex_iterator end;

    // Count the number of matches
    size_t count = 1;
    if (global)
        count = std::distance(begin, end);
    *out_count = count;

    // Allocate an array of `match` structs
    match* matches = new match[count];
    
    size_t i = 0;
    for (auto it = begin; it != end; ++it, ++i) {
        const std::smatch& smatch = *it;
        size_t groups = smatch.size();
        
        // Allocate arrays for strings and positions
        const char** c_strings = new const char*[groups];
        size_t* g_positions = new size_t[groups];

        // Populate the arrays with group strings and positions
        for (size_t j = 0; j < groups; ++j) {
            c_strings[j] = strdup(smatch.str(j).c_str());
            g_positions[j] = smatch.position(j);
        }

        // Store the match data
        matches[i] = { c_strings, g_positions, groups };
        if (!global)
            break;
    }

    return matches;
}

extern "C" const char* zig_regex_format(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format, std::regex_constants::format_no_copy);

    return strdup(result.c_str());
}

extern "C" const wchar_t* zig_wregex_format(std::wregex* r, const wchar_t* str, size_t strlen, const wchar_t* fmt, size_t fmtlen) {
    std::wstring text(str, strlen);
    std::wstring format(fmt, fmtlen);

    std::wstring result = std::regex_replace(text, *r, format, std::regex_constants::format_no_copy);

    return wcsdup(result.c_str());
}

extern "C" void zig_regex_free(std::regex* r) {
    delete r;
}

extern "C" void zig_wregex_free(std::wregex* r) {
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

extern "C" void zig_wregex_free_wmatch(wmatch m) {
    for (size_t i = 0; i < m.groups; ++i)
        free((void*)m.strings[i]);
    delete[] m.positions;
    delete[] m.strings;
}

extern "C" void zig_regex_free_captures(match* m, size_t count) {
    for (size_t i = 0; i < count; ++i)
        zig_regex_free_match(m[i]);
    delete[] m;
}

extern "C" void zig_wregex_free_captures(wmatch* m, size_t count) {
    for (size_t i = 0; i < count; ++i)
        zig_wregex_free_wmatch(m[i]);
    delete[] m;
}