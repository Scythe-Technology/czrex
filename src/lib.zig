const std = @import("std");
const builtin = @import("builtin");

const regex = *align(8) opaque {};
const regex_size = 64;

const match = extern struct {
    strings: [*c][*c]const u8,
    positions: [*c]usize,
    groups: usize,
};

extern "c" fn zig_regex_new([*c]const u8, usize) ?*regex;
extern "c" fn zig_regex_match(*regex, [*c]const u8, usize) bool;
extern "c" fn zig_regex_search(*regex, [*c]const u8, usize) match;
extern "c" fn zig_regex_format(*regex, [*c]const u8, usize, [*c]const u8, usize) [*c]const u8;
extern "c" fn zig_regex_replace(*regex, [*c]const u8, usize, [*c]const u8, usize) [*c]const u8;
extern "c" fn zig_regex_replaceAll(*regex, [*c]const u8, usize, [*c]const u8, usize) [*c]const u8;
extern "c" fn zig_regex_captured_match(*regex, [*c]const u8, usize) match;
extern "c" fn zig_regex_free(*regex) void;
extern "c" fn zig_regex_free_mem(*anyopaque) void;
extern "c" fn zig_regex_free_match(match) void;

pub const Match = struct {
    allocator: std.mem.Allocator,
    groups: []Group,

    pub const Group = struct {
        index: usize,
        slice: []const u8,
    };

    pub fn init(allocator: std.mem.Allocator, m: match) !Match {
        const size = m.groups;
        const groups = try allocator.alloc(Group, size);
        errdefer {
            for (groups) |group| allocator.free(group.slice);
            allocator.free(groups);
        }
        const m_positions = m.positions[0..size];
        for (m.strings[0..size], 0..) |group, i| {
            groups[i] = .{
                .slice = try allocator.dupe(u8, std.mem.span(group)),
                .index = m_positions[i],
            };
        }
        return .{
            .allocator = allocator,
            .groups = groups,
        };
    }

    pub fn deinit(self: Match) void {
        for (self.groups) |group| self.allocator.free(group.slice);
        self.allocator.free(self.groups);
    }
};

pub const Regex = struct {
    allocator: std.mem.Allocator,
    r: **regex,

    pub fn compile(allocator: std.mem.Allocator, pattern: []const u8) !Regex {
        if (zig_regex_new(pattern.ptr, pattern.len)) |ptr| {
            // Really only helpful to let zig know there was an allocation.
            const r_ptr = try allocator.create(*regex);
            r_ptr.* = ptr;
            return .{ .allocator = allocator, .r = r_ptr };
        }
        return error.Fail;
    }

    pub fn isMatch(self: *Regex, text: []const u8) bool {
        return zig_regex_match(self.r.*, text.ptr, text.len);
    }

    pub fn match(self: *Regex, text: []const u8) !?Match {
        const search_result = zig_regex_captured_match(self.r.*, text.ptr, text.len);
        defer zig_regex_free_match(search_result);
        if (search_result.groups == 0) return null;
        return try Match.init(self.allocator, search_result);
    }

    pub fn search(self: *Regex, text: []const u8) !?Match {
        const search_result = zig_regex_search(self.r.*, text.ptr, text.len);
        defer zig_regex_free_match(search_result);
        if (search_result.groups == 0) return null;
        return try Match.init(self.allocator, search_result);
    }

    pub fn allocReplace(self: *Regex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        const result = zig_regex_replace(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len);
        defer zig_regex_free_mem(@constCast(@ptrCast(result)));
        return try allocator.dupe(u8, std.mem.span(result));
    }

    pub fn allocReplaceAll(self: *Regex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        const result = zig_regex_replaceAll(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len);
        defer zig_regex_free_mem(@constCast(@ptrCast(result)));
        return try allocator.dupe(u8, std.mem.span(result));
    }

    pub fn allocFormat(self: *Regex, allocator: std.mem.Allocator, text: []const u8, fmt: []const u8) ![]const u8 {
        const result = zig_regex_format(self.r.*, text.ptr, text.len, fmt.ptr, fmt.len);
        defer zig_regex_free_mem(@constCast(@ptrCast(result)));
        return try allocator.dupe(u8, std.mem.span(result));
    }

    pub fn deinit(self: *Regex) void {
        zig_regex_free(self.r.*);
        self.allocator.destroy(self.r);
    }
};
