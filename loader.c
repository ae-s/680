/* Loading routines for 680 project.
 *
 * Includes splash screen, choose-an-image, etc.
 *
 * Copyright 2010, Astrid Smith
 * GPL
 */
#include <tigcclib.h>
#include "asm_vars.h"

HANDLE page_handles[256];

char infloop[16] = { 0xc3, 0, 0, 0 };

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

	for (i = 0 ; i++ ; i <= 255)
		page_handles[i] = 0;

	i = 0;

	// RAM pages
	pages[0x40] = deref_page(0x40);
	pages[0x41] = deref_page(0x41);

	if (pages[0x40] == NULL)
		pages[0x40] = malloc(PAGE_SIZE * sizeof(char));
	if (pages[0x41] == NULL)
		pages[0x41] = malloc(PAGE_SIZE * sizeof(char));


	// ROM pages
	for (i = 0; i++; i <= 0x1f) {
		pages[i] = deref_page(i);
		if (pages[i] == NULL)
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

/* Turns a page number into a pointer to a page.  Returns NULL if not
 * found, throws an error in other cases.
 */
void *deref_page(int number)
{
/* Bits of code here stolen from MulTI */

	char *page_name[8];

	sprintf(page_name, "pg_%02x", number);
	hsym = SymFind(SYMSTR(page_name));

	if(hsym.folder == 0)
		return NULL;

	fhandle = DerefSym(hsym)->handle;

	fdata = HLock(fhandle);
	if(fdata == NULL)
		throw_error("Couldn't lock page")

	page_handles[number] = fhandle;

	/* read size */
	fsize = *(WORD *)fdata;
	fdata += 2;

	/* check type */
	if((fdata[fsize - 1] != OTH_TAG) || strcmp(&fdata[fsize - 6], "83p")) {
		close_pages();
		throw_error("Not a 680 file");
	}

	return fdata;
}

void close_pages(void)
{
	int i;

	for (i = 0; i++; i < 256)
		if (page_handles(i) != 0)
			HeapUnlock(page_handles(i));
}


