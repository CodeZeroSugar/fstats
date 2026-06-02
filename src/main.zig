const std = @import("std");
const read_file = @import("read_file.zig");
const Io = std.Io;
const Map = std.static_string_map.StaticStringMap;

const Mode = enum { STATS, FIND, HELP };

const ModeMap = Map(Mode).initComptime(.{
    .{ "stats", Mode.STATS },
    .{ "find", Mode.FIND },
    .{ "help", Mode.HELP },
});

pub fn main(init: std.process.Init) !void {
    std.debug.print("Running program...\n", .{});

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    if (args.len < 2) {
        std.debug.print("Not enough args. Try again.\n", .{});
        return;
    }
    const user_selection = args[1];

    const mode = ModeMap.get(user_selection);
    const m = mode orelse {
        std.debug.print("Mode does not exist.\n", .{});
        return;
    };

    switch (m) {
        .STATS => {
            const file_bytes = try read_file.getFileBytes(arena, args[2], init);
            defer arena.free(file_bytes);

            const num_lines = read_file.getNumLines(file_bytes);
            const num_words = read_file.getNumWords(file_bytes);
            const num_vowels = read_file.getNumVowels(file_bytes);

            std.debug.print("Number of lines: {d}\n", .{num_lines});
            std.debug.print("Number of words: {d}\n", .{num_words});
            std.debug.print("Number of vowels: {d}\n", .{num_vowels});
        },
        .FIND => {
            if (args.len != 4) {
                std.debug.print("Search term not provided.\n", .{});
                return;
            }
            const file_bytes = try read_file.getFileBytes(arena, args[2], init);
            defer arena.free(file_bytes);
            const num_found = read_file.getNumFind(file_bytes, args[3]);
            std.debug.print("Number of '{s}' found: {d}\n", .{ args[3], num_found });
        },
        .HELP => {
            std.debug.print("Usage:\nfile_ops stats <relative file path>\nfile_ops find <relative file path> <search term>\nfile_ops help\n", .{});
        },
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
