const std = @import("std");
const builtin = @import("builtin");

const regex = *align(8) opaque {};
const regex_size = 64;

const match = extern struct {
    strings: [*c][*c]const u8,
    groups: usize,
};

extern "c" fn zig_regex_new([*c]const u8, usize) ?*regex;
extern "c" fn zig_regex_match(*regex, [*c]const u8, usize) bool;
extern "c" fn zig_regex_captured_match(*regex, [*c]const u8, usize) match;
extern "c" fn zig_regex_free(*regex) void;
extern "c" fn zig_regex_free_match(match) void;

pub const Match = struct {
    allocator: std.mem.Allocator,
    groups: []const []const u8,

    pub fn init(allocator: std.mem.Allocator, m: match) !Match {
        const groups = try allocator.alloc([]const u8, m.groups);
        errdefer {
            for (groups) |str| allocator.free(str);
            allocator.free(groups);
        }
        for (m.strings[0..m.groups], 0..) |group, i| groups[i] = try allocator.dupe(u8, std.mem.span(group));
        return .{
            .allocator = allocator,
            .groups = groups,
        };
    }

    pub fn getGroups(self: Match) []const []const u8 {
        return self.groups;
    }

    pub fn deinit(self: Match) void {
        for (self.groups) |str| self.allocator.free(str);
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

    pub fn deinit(self: *Regex) void {
        zig_regex_free(self.r.*);
        self.allocator.destroy(self.r);
    }
};
