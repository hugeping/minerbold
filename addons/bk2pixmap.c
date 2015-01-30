#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/fcntl.h>

int main(int argc, char **argv)
{
	int fd;
	unsigned char  color;
	char colors[4] = { '.', 'r', 'g', 'b' };
	off_t pos;
	int w; int h; int y; int x; int i;
	if (argc < 5) {
		fprintf(stderr, "Usage: %s\n"
				"    <bin file> <offset> <w> <h>\n", argv[0]);
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
	w = atoi(argv[3]);
	h = atoi(argv[4]);
	fprintf(stderr, "%d x %d\n", w, h);
	w = (w & 0xfc) + ((w & 3)?4:0);
	fprintf(stderr, "%d x %d\n", w, h);
	fprintf(stdout, "/* XPM */\n"
			"static char *xpm_%lx[] = {\n"
			"/* width height num_colors chars_per_pixel */\n"
			"\" %d %d 4 1\",\n"
			"/* colors */\n"
			"\". c #000000\",\n"
			"\"r c #ff0000\",\n"
			"\"g c #00ff00\",\n"
			"\"b c #0000ff\",\n"
			"/* pixels */\n", (unsigned long)pos, w, h);
	for (y = 0; y < h; y++) {
		fprintf(stdout,"\"");
		for (x = 0; x < w / 4; x++) {
			if (read(fd, &color, sizeof(color)) != sizeof(color)) {
				fprintf(stderr, "Can not read file %s\n", argv[1]);
				return 1;
			}
			for (i = 0; i < 4; i++) {
				fprintf(stdout, "%c", colors[color & 3]);
				color >>= 2;
			}
		}
		fprintf(stdout,"\",\n");
	}
	fprintf(stdout,"};\n");
	close(fd);
	return 0;
}
