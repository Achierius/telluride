const std = @import("std");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub var allocator = &arena.allocator;