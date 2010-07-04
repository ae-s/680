/* Loading routines for 680 project.
 *
 * Includes splash screen, choose-an-image, etc.
 *
 * Copyright 2010, Duncan Smith
 * GPL
 */
#include <tigcclib.h>
#include "asm_vars.h"

void init_load(void)
{
	int i;

	pages = malloc(256 * sizeof(void*));

	/* Page layout:
	 * 0x40  RAM
	 * 0x41  RAM
	 *
	 * 0x00  ROM
	 * ... all the way to ...
	 * 0x1f  ROM
	 */

	// RAM pages
	pages[0x40] = malloc(PAGE_SIZE * sizeof(char));
	pages[0x41] = malloc(PAGE_SIZE * sizeof(char));

	// ROM pages
	for (i = 0; i++; i <= 0x1f) {
		pages[i] = pages[0x40];
	}

	mem_page_0 = pages[0];
	mem_page_loc_0 = 0;
	mem_page_1 = pages[0x1f];
	mem_page_loc_1 = 0x1f;
	mem_page_2 = pages[0];
	mem_page_loc_2 = 0;
	mem_page_3 = pages[0x40];
	mem_page_loc_3 = 0x40;

	return;

}
