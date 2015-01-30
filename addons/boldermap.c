#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/fcntl.h>

int main(int argc, char **argv)
{
	int fd;
	int nr = 0;
	char map[16*16];
	char *ptr = map;
	char syms[] = {
		' ',
		':', // grass
		'@', // stone
		'$', // emerald
		'+', // human
		'#', // block
		'&',
		'%',
	};
	unsigned char  color;
	off_t pos;
	int n; int x; int y; int i;
	if (argc < 4) {
		fprintf(stderr, "Usage: %s\n"
				"    <bin file> <offset> <n>\n", argv[0]);
		return 1;
	}
	fd = open(argv[1], O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "Can not open file %s\n", argv[1]);
		return 1;
	}
	pos = strtol(argv[2], NULL, 0);
	fprintf(stderr,"%s @ %lx\n", argv[1], (unsigned long)pos);
	if (lseek(fd, pos, SEEK_SET) < 0) {
		fprintf(stderr, "Can not seek file %s\n", argv[1]);
		return 1;
	}
	n = atoi(argv[3]);
	fprintf(stderr, "%d map(s)\n", n);
	fprintf(stdout,"maps = {\n");
	while (n--) {
		ptr = map;
		for (i = 0; i < 52; i++) {
			unsigned short w16;
			int nn = 5;
			if (read(fd, &w16, sizeof(w16)) != sizeof(w16)) {
				fprintf(stderr, "Can not read file %s\n", argv[1]);
				return 1;
			}
			w16 <<= 1;
			if (i == 51) 
				nn = 1;
			while (nn--) {
				*ptr = (w16 & 0xe000) >> (16 - 3);
				ptr ++;
				w16 <<= 3;
			}
		}
		fprintf(stdout,"-- %d\n", nr);
		for (y = 0; y < 16; y++) {
			fprintf(stdout,"\"");
			for (x = 0; x < 16; x++) {
				fprintf(stdout, "%c", syms[map[y * 16 + x]] );
			}
			fprintf(stdout,"\",\n");
		}
		nr ++;
	}
	fprintf(stdout,"};\n");
	close(fd);
	return 0;
}
