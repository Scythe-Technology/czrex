#include <vector>
#include <regex>
#include <string>

extern "C" struct match {
    const char** strings;
    size_t groups;
};

extern "C" std::regex* zig_regex_new(const char* cstr, size_t len) {
    std::string pattern(cstr, len);
    try {
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

    const char** c_strings = new const char*[match.size()];
  
    for (size_t j = 0; j < match.size(); ++j)
        c_strings[j] = strdup(match[j].str().c_str());

    return { c_strings, match.size() };
}

extern "C" void zig_regex_free(std::regex* r) {
    delete r;
}

extern "C" void zig_regex_free_match(match m) {
    for (size_t i = 0; i < m.groups; ++i)
        free((void*)m.strings[i]);
    delete[] m.strings;
}