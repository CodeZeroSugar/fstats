const std = @import("std");
const file = std.Io.File;
const Io = std.Io;

pub fn getFileBytes(allocator: std.mem.Allocator, file_name: []const u8, init: std.process.Init) ![]const u8 {
    const flags = file.OpenFlags{
        .mode = file.OpenMode.read_only,
    };
    const f = try Io.Dir.cwd().openFile(init.io, file_name, flags);
    defer f.close(init.io);
    const stat = try f.stat(init.io);
    const file_size = stat.size;

    var read_buff: [1024]u8 = undefined;

    const buffer = try allocator.alloc(u8, file_size);

    var reader = f.reader(init.io, &read_buff);
    try reader.interface.readSliceAll(buffer);

    return buffer;
}

pub fn getNumLines(file_bytes: []const u8) usize {
    var count: usize = 0;
    for (file_bytes) |c| {
        if (c == '\n') {
            count += 1;
        }
    }
    return count;
}

pub fn getNumWords(file_bytes: []const u8) usize {
    var words = std.mem.tokenizeScalar(u8, file_bytes, ' ');
    var count: usize = 0;

    while (words.next()) |_| {
        count += 1;
    }
    return count;
}

pub fn getNumVowels(file_bytes: []const u8) usize {
    var count: usize = 0;

    for (file_bytes) |c| {
        switch (c) {
            'A', 'E', 'I', 'O', 'U', 'a', 'e', 'i', 'o', 'u' => count += 1,
            else => {},
        }
    }

    return count;
}

pub fn getNumFind(file_bytes: []const u8, target: []const u8) usize {
    var count: usize = 0;
    var words = std.mem.tokenizeAny(u8, file_bytes, " \t\r\n.,!?;:()[]{}\"'");

    while (words.next()) |word| {
        if (std.mem.eql(u8, word, target)) {
            count += 1;
        }
    }
    return count;
}
