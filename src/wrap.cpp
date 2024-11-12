#include <vector>
#include <regex>
#include <string>
#include <iterator>

char* bufcopy(const char* buf, size_t len) {
    char* copy = new char[len];
    memcpy(copy, buf, len);
    return copy;
}

wchar_t* wbufcopy(const wchar_t* buf, size_t len) {
    wchar_t* copy = new wchar_t[len];
    std::memcpy(copy, buf, len * sizeof(wchar_t));
    return copy;
}

extern "C" struct match {
    const char** strings;
    size_t* positions;
    size_t* sizes;
    size_t size;
};

extern "C" struct wmatch {
    const wchar_t** strings;
    size_t* positions;
    size_t* sizes;
    size_t size;
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

    size_t size = match.size();
    const char** c_strings = new const char*[size];
    size_t* g_positions = new size_t[size];
    size_t* g_sizes = new size_t[size];
  
    for (size_t j = 0; j < match.size(); ++j) {
        std::string str = match.str(j);
        c_strings[j] = bufcopy(str.c_str(), str.size());
        g_positions[j] = match.position(j);
        g_sizes[j] = str.size();
    }

    return { c_strings, g_positions, g_sizes, size };
}

extern "C" wmatch zig_wregex_captured_match(std::wregex* r, const wchar_t* cstr, size_t len) {
    std::wsmatch match;
    std::wstring text(cstr, len);
    std::regex_match(text, match, *r);

    size_t size = match.size();
    const wchar_t** c_strings = new const wchar_t*[size];
    size_t* g_positions = new size_t[size];
    size_t* g_sizes = new size_t[size];
  
    for (size_t j = 0; j < match.size(); ++j) {
        std::wstring str = match.str(j);
        c_strings[j] = wbufcopy(str.c_str(), str.size());
        g_positions[j] = match.position(j);
        g_sizes[j] = str.size();
    }

    return { c_strings, g_positions, g_sizes, size };
}

extern "C" match zig_regex_search(std::regex* r, const char* cstr, size_t len) {
    std::smatch match;
    std::string text(cstr, len);
    std::regex_search(text, match, *r);

    size_t size = match.size();
    const char** c_strings = new const char*[size];
    size_t* g_positions = new size_t[size];
    size_t* g_sizes = new size_t[size];
  
    for (size_t j = 0; j < match.size(); ++j) {
        std::string str = match.str(j);
        c_strings[j] = bufcopy(str.c_str(), str.size());
        g_positions[j] = match.position(j);
        g_sizes[j] = str.size();
    }

    return { c_strings, g_positions, g_sizes, size };
}

extern "C" wmatch zig_wregex_search(std::wregex* r, const wchar_t* cstr, size_t len) {
    std::wsmatch match;
    std::wstring text(cstr, len);
    std::regex_search(text, match, *r);

    size_t size = match.size();
    const wchar_t** c_strings = new const wchar_t*[size];
    size_t* g_positions = new size_t[size];
    size_t* g_sizes = new size_t[size];
  
    for (size_t j = 0; j < match.size(); ++j) {
        std::wstring str = match.str(j);
        c_strings[j] = wbufcopy(str.c_str(), str.size());
        g_positions[j] = match.position(j);
        g_sizes[j] = str.size();
    }

    return { c_strings, g_positions, g_sizes, size };
}

extern "C" const char* zig_regex_replace(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen, size_t* outlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format, std::regex_constants::format_first_only);

    if (outlen != nullptr)
        *outlen = result.size();

    return bufcopy(result.c_str(), result.size());
}

extern "C" const wchar_t* zig_wregex_replace(std::wregex* r, const wchar_t* str, size_t strlen, const wchar_t* fmt, size_t fmtlen, size_t* outlen) {
    std::wstring text(str, strlen);
    std::wstring format(fmt, fmtlen);

    std::wstring result = std::regex_replace(text, *r, format, std::regex_constants::format_first_only);

    if (outlen != nullptr)
        *outlen = result.size();

    return wbufcopy(result.c_str(), result.size());
}

extern "C" const char* zig_regex_replaceAll(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen, size_t* outlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format);

    if (outlen != nullptr)
        *outlen = result.size();


    return bufcopy(result.c_str(), result.size());
}

extern "C" const wchar_t* zig_wregex_replaceAll(std::wregex* r, const wchar_t* str, size_t strlen, const wchar_t* fmt, size_t fmtlen, size_t* outlen) {
    std::wstring text(str, strlen);
    std::wstring format(fmt, fmtlen);

    std::wstring result = std::regex_replace(text, *r, format);

    if (outlen != nullptr)
        *outlen = result.size();


    return wbufcopy(result.c_str(), result.size());
}

extern "C" match* zig_regex_captures(std::regex* r, const char* cstr, size_t len, size_t* out_count, bool global) {
    std::string text(cstr, len);
    std::sregex_iterator begin(text.begin(), text.end(), *r);
    std::sregex_iterator end;

    // Count the number of matches
    size_t count = std::distance(begin, end);
    if (global && count > 1)
        count = 1;
    *out_count = count;

    // Allocate an array of `match` structs
    match* matches = new match[count];
    
    size_t i = 0;
    for (auto it = begin; it != end; ++it, ++i) {
        const std::smatch& match = *it;
        size_t size = match.size();
        
        // Allocate arrays for strings and positions
        const char** c_strings = new const char*[size];
        size_t* g_positions = new size_t[size];
        size_t* g_sizes = new size_t[size];

        // Populate the arrays with group strings and positions
        for (size_t j = 0; j < size; ++j) {
            std::string str = match.str(j);
            c_strings[j] = bufcopy(str.c_str(), str.size());
            g_positions[j] = match.position(j);
            g_sizes[j] = str.size();
        }

        // Store the match data
        matches[i] = { c_strings, g_positions, g_sizes, size };
        if (!global)
            break;
    }

    return matches;
}

extern "C" wmatch* zig_wregex_captures(std::wregex* r, const wchar_t* cstr, size_t len, size_t* out_count, bool global) {
    std::wstring text(cstr, len);
    std::wsregex_iterator begin(text.begin(), text.end(), *r);
    std::wsregex_iterator end;

    // Count the number of matches
    size_t count = std::distance(begin, end);
    if (global && count > 1)
        count = 1;
    *out_count = count;

    // Allocate an array of `match` structs
    wmatch* matches = new wmatch[count];
    
    size_t i = 0;
    for (auto it = begin; it != end; ++it, ++i) {
        const std::wsmatch& match = *it;
        size_t size = match.size();
        
        // Allocate arrays for strings and positions
        const wchar_t** c_strings = new const wchar_t*[size];
        size_t* g_positions = new size_t[size];
        size_t* g_sizes = new size_t[size];

        // Populate the arrays with group strings and positions
        for (size_t j = 0; j < size; ++j) {
            std::wstring str = match.str(j);
            c_strings[j] = wbufcopy(str.c_str(), str.size());
            g_positions[j] = match.position(j);
            g_sizes[j] = str.size();
        }

        // Store the match data
        matches[i] = { c_strings, g_positions, g_sizes, size };
        if (!global)
            break;
    }

    return matches;
}

extern "C" const char* zig_regex_format(std::regex* r, const char* str, size_t strlen, const char* fmt, size_t fmtlen, size_t* outlen) {
    std::string text(str, strlen);
    std::string format(fmt, fmtlen);

    std::string result = std::regex_replace(text, *r, format, std::regex_constants::format_no_copy);

    if (outlen != nullptr)
        *outlen = result.size();

    return bufcopy(result.c_str(), result.size());
}

extern "C" const wchar_t* zig_wregex_format(std::wregex* r, const wchar_t* str, size_t strlen, const wchar_t* fmt, size_t fmtlen, size_t* outlen) {
    std::wstring text(str, strlen);
    std::wstring format(fmt, fmtlen);

    std::wstring result = std::regex_replace(text, *r, format, std::regex_constants::format_no_copy);

    if (outlen != nullptr)
        *outlen = result.size();

    return wbufcopy(result.c_str(), result.size());
}

extern "C" void zig_regex_free(std::regex* r) {
    delete r;
}

extern "C" void zig_wregex_free(std::wregex* r) {
    delete r;
}

extern "C" void zig_regex_delete(const char* buf) {
    delete[] buf;
}

extern "C" void zig_wregex_delete(const wchar_t* buf) {
    delete[] buf;
}

extern "C" void zig_regex_free_match(match m) {
    for (size_t i = 0; i < m.size; ++i)
        zig_regex_delete(m.strings[i]);
    delete[] m.positions;
    delete[] m.strings;
    delete[] m.sizes;
}

extern "C" void zig_wregex_free_wmatch(wmatch m) {
    for (size_t i = 0; i < m.size; ++i)
        zig_wregex_delete(m.strings[i]);
    delete[] m.positions;
    delete[] m.strings;
    delete[] m.sizes;
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