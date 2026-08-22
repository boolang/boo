// Translation of program into elf executable binaries

f gen_header(entry_point: I, base_addr: I, text_size: I, program: S) -> S {
    // e_ident (\x7FELF then a bunch of random stuff (i just copied a random binary))
    l ident = S_concat(S_concat(S_concat(S_concat(S_new_from_char(I_chr(0x7f)), "ELF"), I_u32_to_bytes(0x00010102)), S_new_from_char(I_chr(0))), "meow :3");
    // e_type (ET_EXEC)
    l type = I_u16_to_bytes(3);
    // e_machine (62 is x86 i think)
    l machine = I_u16_to_bytes(62);
    // e_version (1 means current)
    l version = I_u32_to_bytes(1);
    // e_entry (entry point addr in virtual memory)
    l entry = I_u64_to_bytes(entry_point);
    // e_phoff (program header offset which will be immediately after the elf header)
    l phoff = I_u64_to_bytes(64);
    // e_shoff (section header offset which is unused)
    l shoff = I_u64_to_bytes(0);
    // e_flags (idk lol)
    l flags = I_u32_to_bytes(0);
    // e_ehsize (linux doesn't care about it)
    l ehsize = I_u16_to_bytes(64);
    // e_phentsize (size of program headers (WHY IS IT NOT A POWER OF TWO???))
    l phentsize = I_u16_to_bytes(56);
    // e_phnum (number of program headers)
    l phnum = I_u16_to_bytes(1);
    // e_shentsize (size of section headers (dont care))
    l shentsize = I_u16_to_bytes(0);
    // e_shnum (number of section headers (dont care))
    l shnum = I_u16_to_bytes(0);
    // e_shstrndx (section header string table index (dont care))
    l shstrndx = I_u16_to_bytes(0);

    l elf_header = S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(
    ident, type), machine), version), entry), phoff), shoff), flags), ehsize), phentsize), phnum), shentsize), shnum), shstrndx);

    // then we do the program headers! we only have one segment :3
    // p_type (1 is loadable segment)
    l p_type = I_u32_to_bytes(1);
    // p_flags (RWX lolololol)
    l p_flags = I_u32_to_bytes(7);
    // p_offset (where in the file the segment is read from (so right after this header))
    l p_offset = I_u64_to_bytes(0);
    // p_vaddr (where in virtual memory to have this loaded to)
    l p_vaddr = I_u64_to_bytes(base_addr);
    // p_paddr (linux doesn't care)
    l p_paddr = I_u64_to_bytes(base_addr);
    // p_filesz (size of the segment in the file)
    l p_filesz = I_u64_to_bytes(text_size);
    // p_memsz (size of the segment in memory)
    l p_memsz = I_u64_to_bytes(text_size);
    // p_align (alignment of segments which we don't care about :3)
    l p_align = I_u64_to_bytes(0x1000);

    l p_header = S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(S_concat(
    p_type, p_flags), p_offset), p_vaddr), p_paddr), p_filesz), p_memsz), p_align);

    r S_concat(S_concat(elf_header, p_header), program);
}

f gen_elf(program: Program) -> S {
    r gen_header(0, 0, 0);
}
