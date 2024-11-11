const std = @import("std");
const builtin = @import("builtin");

const regex = *align(8) opaque {};
const wregex = *align(8) opaque {};
const regex_size = 64;

pub const p_char = u8;
pub const p_wchar = u32;

const match = extern struct {
    strings: [*c][*c]p_char,
    positions: [*c]usize,
    sizes: [*c]usize,
    size: usize,
};

const wmatch = extern struct {
    strings: [*c][*c]p_wchar,
    positions: [*c]usize,
    sizes: [*c]usize,
    size: usize,
};

pub const FLAG_ECMASCRIPT = 0;
pub const FLAG_IGNORECASE = 1 << 0;
pub const FLAG_NOSUBS = 1 << 1;
pub const FLAG_OPTIMIZE = 1 << 2;
pub const FLAG_COLLATE = 1 << 3;
pub const FLAG_BASIC = 1 << 4;
pub const FLAG_EXTENDED = 1 << 5;
pub const FLAG_AWK = 1 << 6;
pub const FLAG_GREP = 1 << 7;
pub const FLAG_EGREP = 1 << 8;
pub const FLAG_MULTILINE = 1 << 10;

extern "c" fn zig_regex_new([*c]const p_char, usize, c_int) ?regex;
extern "c" fn zig_wregex_new([*c]const p_wchar, usize, c_int) ?wregex;
extern "c" fn zig_regex_match(regex, [*c]const p_char, usize) bool;
extern "c" fn zig_wregex_match(wregex, [*c]const p_wchar, usize) bool;
extern "c" fn zig_regex_captures(regex, [*c]const p_char, usize, *usize, bool) [*c]match;
extern "c" fn zig_wregex_captures(wregex, [*c]const p_wchar, usize, *usize, bool) [*c]wmatch;
extern "c" fn zig_regex_search(regex, [*c]const p_char, usize) match;
extern "c" fn zig_wregex_search(wregex, [*c]const p_wchar, usize) wmatch;
extern "c" fn zig_regex_format(regex, [*c]const p_char, usize, [*c]const p_char, usize, *usize) [*c]const p_char;
extern "c" fn zig_wregex_format(wregex, [*c]const p_wchar, usize, [*c]const p_wchar, usize, *usize) [*c]const p_wchar;
extern "c" fn zig_regex_replace(regex, [*c]const p_char, usize, [*c]const p_char, usize, *usize) [*c]const p_char;
extern "c" fn zig_wregex_replace(wregex, [*c]const p_wchar, usize, [*c]const p_wchar, usize, *usize) [*c]const p_wchar;
extern "c" fn zig_regex_replaceAll(regex, [*c]const p_char, usize, [*c]const p_char, usize, *usize) [*c]const p_char;
extern "c" fn zig_wregex_replaceAll(wregex, [*c]const p_wchar, usize, [*c]const p_wchar, usize, *usize) [*c]const p_wchar;
extern "c" fn zig_regex_captured_match(regex, [*c]const p_char, usize) match;
extern "c" fn zig_wregex_captured_match(wregex, [*c]const p_wchar, usize) wmatch;
extern "c" fn zig_regex_free(regex) void;
extern "c" fn zig_wregex_free(wregex) void;
extern "c" fn zig_regex_delete([*c]const p_char) void;
extern "c" fn zig_wregex_delete([*c]const p_wchar) void;
extern "c" fn zig_regex_free_match(match) void;
extern "c" fn zig_wregex_free_wmatch(wmatch) void;
extern "c" fn zig_regex_free_captures([*c]match, usize) void;
extern "c" fn zig_wregex_free_captures([*c]wmatch, usize) void;

pub const Match = struct {
    allocator: std.mem.Allocator,
    groups: []Group,

    pub const Group = struct {
        index: usize,
        slice: []const u8,
    };

    pub fn init(allocator: std.mem.Allocator, m: match) !Match {
        const size = m.size;
        const groups = try allocator.alloc(Group, size);
        var count: usize = 0;
        errdefer {
            for (0..count) |i|
                allocator.free(groups[i].slice);
            allocator.free(groups);
        }
        const m_positions = m.positions[0..size];
        for (m.strings[0..size], 0..) |group, i| {
            groups[i] = .{
                .slice = try allocator.dupe(p_char, group[0..m.sizes[i]]),
                .index = m_positions[i],
            };
            count = i;
        }
        return .{
            .allocator = allocator,
            .groups = groups,
        };
    }

    pub fn fromWMatch(allocator: std.mem.Allocator, wm: WMatch) !Match {
        const size = wm.groups.len;
        const groups = try allocator.alloc(Group, size);
        var count: usize = 0;
        errdefer {
            for (0..count) |i|
                allocator.free(groups[i].slice);
            allocator.free(groups);
        }
        for (wm.groups, 0..) |group, i| {
            groups[i] = .{
                .slice = try utfWideLeToUtf8Alloc(allocator, group.slice),
                .index = group.index,
            };
            count = i;
        }
        return .{
            .allocator = allocator,
            .groups = groups,
        };
    }

    pub fn deinit(self: Match) void {
        for (self.groups) |group|
            self.allocator.free(group.slice);
        self.allocator.free(self.groups);
    }
};

pub const WMatch = struct {
    allocator: std.mem.Allocator,
    groups: []Group,

    pub const Group = struct {
        index: usize,
        slice: []const p_wchar,
    };

    pub fn init(allocator: std.mem.Allocator, m: wmatch) !WMatch {
        const size = m.size;
        const groups = try allocator.alloc(Group, size);
        var count: usize = 0;
        errdefer {
            for (0..count) |i|
                allocator.free(groups[i].slice);
            allocator.free(groups);
        }
        const m_positions = m.positions[0..size];
        for (m.strings[0..size], 0..) |group, i| {
            groups[i] = .{
                .slice = try allocator.dupe(p_wchar, group[0..m.sizes[i]]),
                .index = m_positions[i],
            };
            count += 1;
        }
        return .{
            .allocator = allocator,
            .groups = groups,
        };
    }

    pub fn deinit(self: WMatch) void {
        for (self.groups) |group|
            self.allocator.free(group.slice);
        self.allocator.free(self.groups);
    }
};

pub const Captures = struct {
    allocator: std.mem.Allocator,
    captures: []const Match,

    pub fn fromWCaptures(allocator: std.mem.Allocator, wc: WCaptures) !Captures {
        const size = wc.captures.len;
        const captures = try allocator.alloc(Match, size);
        var count: usize = 0;
        errdefer {
            for (0..count) |i|
                captures[i].deinit();
            allocator.free(captures);
        }
        for (wc.captures, 0..) |capture, i| {
            captures[i] = try Match.fromWMatch(allocator, capture);
            count = i;
        }
        return .{
            .allocator = allocator,
            .captures = captures,
        };
    }

    pub fn deinit(self: Captures) void {
        for (self.captures) |capture|
            capture.deinit();
        self.allocator.free(self.captures);
    }
};

pub const WCaptures = struct {
    allocator: std.mem.Allocator,
    captures: []const WMatch,

    pub fn deinit(self: WCaptures) void {
        for (self.captures) |capture|
            capture.deinit();
        self.allocator.free(self.captures);
    }
};

pub fn utf8ToUtf32LeAlloc(allocator: std.mem.Allocator, slice: []const u8) ![]const u32 {
    var result = try std.ArrayList(u32).initCapacity(allocator, slice.len);
    errdefer result.deinit();
    var utf8Iter = std.unicode.Utf8Iterator{
        .bytes = slice,
        .i = 0,
    };
    while (utf8Iter.nextCodepoint()) |code|
        try result.append(@intCast(code));
    return try result.toOwnedSlice();
}

pub fn utf32LeToUtf8Alloc(allocator: std.mem.Allocator, slice: []const u32) ![]const u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, slice.len);
    errdefer result.deinit();
    for (slice) |code| {
        const codepoint: u21 = @truncate(code);
        var bytes: [4]u8 = undefined;
        const len = try std.unicode.utf8Encode(codepoint, &bytes);
        try result.appendSlice(bytes[0..len]);
    }
    return try result.toOwnedSlice();
}

pub fn utf8ToUtfWideLeAlloc(allocator: std.mem.Allocator, slice: []const u8) ![]const p_wchar {
    if (!std.unicode.utf8ValidateSlice(slice))
        return error.InvalidUtf8;
    return utf8ToUtf32LeAlloc(allocator, slice);
}

pub fn utfWideLeToUtf8Alloc(allocator: std.mem.Allocator, slice: []const p_wchar) ![]const p_char {
    return utf32LeToUtf8Alloc(allocator, slice);
}

pub const WRegex = struct {
    allocator: std.mem.Allocator,
    r: *wregex,

    pub fn compile(allocator: std.mem.Allocator, pattern: []const u8, flag: ?c_int) !WRegex {
        const pattern_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, pattern);
        defer allocator.free(pattern_wide);

        return WRegex.compileW(allocator, pattern_wide, flag);
    }

    pub fn compileW(allocator: std.mem.Allocator, pattern: []const p_wchar, flag: ?c_int) !WRegex {
        if (zig_wregex_new(pattern.ptr, pattern.len, flag orelse -1)) |ptr| {
            // Really only helpful to let zig know there was an allocation.
            const r_ptr = try allocator.create(wregex);
            r_ptr.* = ptr;
            return .{ .allocator = allocator, .r = r_ptr };
        }
        return error.Fail;
    }

    pub fn isMatch(self: *WRegex, text: []const u8) !bool {
        if (!std.unicode.utf8ValidateSlice(text))
            return false;

        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(self.allocator, text);
        defer self.allocator.free(text_wide);

        return self.isMatchW(text_wide);
    }

    pub inline fn isMatchW(self: *WRegex, text: []const p_wchar) bool {
        return zig_wregex_match(self.r.*, text.ptr, text.len);
    }

    pub fn match(self: *WRegex, text: []const u8) !?Match {
        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(self.allocator, text);
        defer self.allocator.free(text_wide);

        const result = try self.matchW(text_wide) orelse return null;
        defer result.deinit();

        return try Match.fromWMatch(self.allocator, result);
    }

    pub fn matchW(self: *WRegex, text: []const p_wchar) !?WMatch {
        const search_result = zig_wregex_captured_match(self.r.*, text.ptr, text.len);
        defer zig_wregex_free_wmatch(search_result);
        if (search_result.size == 0)
            return null;
        return try WMatch.init(self.allocator, search_result);
    }

    pub fn capturesAlloc(self: *WRegex, allocator: std.mem.Allocator, text: []const u8, global: bool) !Captures {
        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, text);
        defer allocator.free(text_wide);

        const reuslt = try self.capturesAllocW(allocator, text_wide, global);
        defer reuslt.deinit();

        return Captures.fromWCaptures(allocator, reuslt);
    }

    pub fn capturesAllocW(self: *WRegex, allocator: std.mem.Allocator, text: []const p_wchar, global: bool) !WCaptures {
        var count: usize = 0;
        const search_result = zig_wregex_captures(self.r.*, text.ptr, text.len, &count, global);
        defer zig_wregex_free_captures(search_result, count);

        const matches = try allocator.alloc(WMatch, count);
        var alloc_c: usize = 0;
        errdefer {
            for (0..alloc_c) |i|
                matches[i].deinit();
            allocator.free(matches);
        }

        for (0..count) |i| {
            matches[i] = try WMatch.init(allocator, search_result[i]);
            alloc_c += 1;
        }

        return .{
            .allocator = allocator,
            .captures = matches,
        };
    }

    pub fn search(self: *WRegex, text: []const u8) !?Match {
        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(self.allocator, text);
        defer self.allocator.free(text_wide);

        const result = try self.searchW(text_wide) orelse return null;
        defer result.deinit();

        return try Match.fromWMatch(self.allocator, result);
    }

    pub fn searchW(self: *WRegex, text: []const p_wchar) !?WMatch {
        const search_result = zig_wregex_search(self.r.*, text.ptr, text.len);
        defer zig_wregex_free_wmatch(search_result);
        if (search_result.size == 0)
            return null;
        return try WMatch.init(self.allocator, search_result);
    }

    pub fn allocReplace(self: *WRegex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, text);
        defer allocator.free(text_wide);

        const fmt_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, fmt);
        defer allocator.free(fmt_wide);

        const result = try self.allocReplaceW(allocator, text_wide, fmt_wide);
        defer allocator.free(result);

        return try utfWideLeToUtf8Alloc(allocator, result);
    }

    pub fn allocReplaceW(self: *WRegex, allocator: std.mem.Allocator, text: []const p_wchar, fmt: []const p_wchar) ![]const p_wchar {
        var length: usize = 0;
        const result = zig_wregex_replace(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len, &length);
        defer zig_wregex_delete(result);
        return try allocator.dupe(p_wchar, result[0..length]);
    }

    pub fn allocReplaceAll(self: *WRegex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, text);
        defer allocator.free(text_wide);

        const fmt_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, fmt);
        defer allocator.free(fmt_wide);

        const result = try self.allocReplaceAllW(allocator, text_wide, fmt_wide);
        defer allocator.free(result);

        return try utfWideLeToUtf8Alloc(allocator, result);
    }

    pub fn allocReplaceAllW(self: *WRegex, allocator: std.mem.Allocator, text: []const p_wchar, fmt: []const p_wchar) ![]const p_wchar {
        var length: usize = 0;
        const result = zig_wregex_replaceAll(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len, &length);
        defer zig_wregex_delete(result);
        return try allocator.dupe(p_wchar, result[0..length]);
    }

    pub fn allocFormat(self: *WRegex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        const text_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, text);
        defer allocator.free(text_wide);

        const fmt_wide: []const p_wchar = try utf8ToUtfWideLeAlloc(allocator, fmt);
        defer allocator.free(fmt_wide);

        const result = try self.allocFormatW(allocator, text_wide, fmt_wide);
        defer allocator.free(result);

        return try utfWideLeToUtf8Alloc(allocator, result);
    }

    pub fn allocFormatW(self: *WRegex, allocator: std.mem.Allocator, text: []const p_wchar, fmt: []const p_wchar) ![]const p_wchar {
        var length: usize = 0;
        const result = zig_wregex_format(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len, &length);
        defer zig_wregex_delete(result);
        return try allocator.dupe(p_wchar, result[0..length]);
    }

    pub fn deinit(self: *WRegex) void {
        zig_wregex_free(self.r.*);
        self.allocator.destroy(self.r);
    }
};

pub const Regex = struct {
    allocator: std.mem.Allocator,
    r: *regex,

    pub fn compile(allocator: std.mem.Allocator, pattern: []const u8, flag: ?c_int) !Regex {
        if (zig_regex_new(pattern.ptr, pattern.len, flag orelse -1)) |ptr| {
            // Really only helpful to let zig know there was an allocation.
            const r_ptr = try allocator.create(regex);
            r_ptr.* = ptr;
            return .{ .allocator = allocator, .r = r_ptr };
        }
        return error.Fail;
    }

    pub inline fn isMatch(self: *Regex, text: []const u8) bool {
        return zig_regex_match(self.r.*, text.ptr, text.len);
    }

    pub fn match(self: *Regex, text: []const u8) !?Match {
        const search_result = zig_regex_captured_match(self.r.*, text.ptr, text.len);
        defer zig_regex_free_match(search_result);
        if (search_result.size == 0)
            return null;
        return try Match.init(self.allocator, search_result);
    }

    pub fn capturesAlloc(self: *Regex, allocator: std.mem.Allocator, text: []const u8, global: bool) !Captures {
        var count: usize = 0;
        const search_result = zig_regex_captures(self.r.*, text.ptr, text.len, &count, global);
        defer zig_regex_free_captures(search_result, count);

        const matches = try allocator.alloc(Match, count);
        var alloc_c: usize = 0;
        errdefer {
            for (0..alloc_c) |i|
                matches[i].deinit();
            allocator.free(matches);
        }

        for (0..count) |i| {
            matches[i] = try Match.init(allocator, search_result[i]);
            alloc_c += 1;
        }

        return .{
            .allocator = allocator,
            .captures = matches,
        };
    }

    pub fn search(self: *Regex, text: []const u8) !?Match {
        const search_result = zig_regex_search(self.r.*, text.ptr, text.len);
        defer zig_regex_free_match(search_result);
        if (search_result.size == 0)
            return null;
        return try Match.init(self.allocator, search_result);
    }

    pub fn allocReplace(self: *Regex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        var length: usize = 0;
        const result = zig_regex_replace(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len, &length);
        defer zig_regex_delete(result);
        return try allocator.dupe(p_char, result[0..length]);
    }

    pub fn allocReplaceAll(self: *Regex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        var length: usize = 0;
        const result = zig_regex_replaceAll(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len, &length);
        defer zig_regex_delete(result);
        return try allocator.dupe(p_char, result[0..length]);
    }

    pub fn allocFormat(self: *Regex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        var length: usize = 0;
        const result = zig_regex_format(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len, &length);
        defer zig_regex_delete(result);
        return try allocator.dupe(p_char, result[0..length]);
    }

    pub fn deinit(self: *Regex) void {
        zig_regex_free(self.r.*);
        self.allocator.destroy(self.r);
    }
};
