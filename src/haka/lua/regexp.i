/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

%{
#include <haka/regexp_module.h>

static char *escape_chars(const char *STRING, size_t SIZE) {
	int iter = 0;
	char *str;
	str = malloc(SIZE + 1);
	if (!str) {
		error(L"memory error");
		return NULL;
	}
	while (iter < SIZE) {
		if (STRING[iter] == '%') {
			str[iter] = '\\';
			iter++;
		}
		if (iter < SIZE) {
			str[iter] = STRING[iter];
		}
		iter++;
	}
	str[SIZE] = '\0';
	return str;
}
%}

struct regexp_result {
	int offset;
	int size;

	%extend {
		~regexp_result() {
			free($self);
		}
	}
};

struct regexp_vbresult {
	int offset;
	int size;

	%extend {
		~regexp_vbresult() {
			free($self);
		}
	}
};

struct regexp_sink {
	%extend {
		bool feed(const char *STRING, size_t SIZE, bool eof=false,
		          struct regexp_result **OUTPUT) {
			int ret = $self->regexp->module->feed($self, STRING, SIZE, eof);

			if (ret == REGEXP_MATCH) {
				*OUTPUT = malloc(sizeof(struct regexp_result));
				if (!*OUTPUT)
					error(L"memory error");
				**OUTPUT = $self->result;
			} else {
				*OUTPUT = NULL;
			}

			return (ret == REGEXP_MATCH);
		}

		bool feed(struct vbuffer_sub *vbuf, bool eof=false,
		          struct regexp_result **OUTPUT) {
			int ret = $self->regexp->module->vbfeed($self, vbuf, eof);

			if (ret == REGEXP_MATCH) {
				*OUTPUT = malloc(sizeof(struct regexp_result));
				if (!*OUTPUT)
					error(L"memory error");
				**OUTPUT = $self->result;
			} else {
				*OUTPUT = NULL;
			}

			return (ret == REGEXP_MATCH);
		}

		bool ispartial() {
			return ($self->match == REGEXP_PARTIAL);
		}

		~regexp_sink() {
			$self->regexp->module->free_regexp_sink($self);
		}
	}
};

%newobject regexp::create_sink;
struct regexp {
	%extend {
		bool match(const char *STRING, size_t SIZE,
		           struct regexp_result **OUTPUT) {
			*OUTPUT = malloc(sizeof(struct regexp_result));
			if (!*OUTPUT)
				error(L"memory error");

			int ret = $self->module->exec($self, STRING, SIZE, *OUTPUT);

			if (ret != REGEXP_MATCH) {
				free(*OUTPUT);
				*OUTPUT = NULL;
			}

			return (ret == REGEXP_MATCH);
		}

		bool match(struct vbuffer_sub *vbuf,
		           struct regexp_vbresult **OUTPUT) {
			*OUTPUT = malloc(sizeof(struct regexp_vbresult));
			if (!*OUTPUT)
				error(L"memory error");

			int ret = $self->module->vbexec($self, vbuf, *OUTPUT);

			if (ret != REGEXP_MATCH) {
				free(*OUTPUT);
				*OUTPUT = NULL;
			}

			return (ret == REGEXP_MATCH);
		}

		struct regexp_sink *create_sink() {
			return $self->module->create_sink($self);
		}

		~regexp() {
			$self->module->release_regexp($self);
		}
	}
};

%newobject regexp_module::compile;
struct regexp_module {
	%extend {
		bool match(const char *pattern, const char *STRING, size_t SIZE,
		           struct regexp_result **OUTPUT) {
			*OUTPUT = malloc(sizeof(struct regexp_vbresult));
			if (!*OUTPUT)
				error(L"memory error");

			char *esc_regexp = escape_chars(pattern, strlen(pattern));
			int ret = $self->match(esc_regexp, STRING, SIZE, *OUTPUT);
			free(esc_regexp);

			if (ret != REGEXP_MATCH) {
				free(*OUTPUT);
				*OUTPUT = NULL;
			}

			return (ret == REGEXP_MATCH);
		}

		bool match(const char *pattern, struct vbuffer_sub *vbuf,
		           struct regexp_vbresult **OUTPUT) {
			*OUTPUT = malloc(sizeof(struct regexp_vbresult));
			if (!*OUTPUT)
				error(L"memory error");

			char *esc_regexp = escape_chars(pattern, strlen(pattern));
			int ret = $self->vbmatch(esc_regexp, vbuf, *OUTPUT);
			free(esc_regexp);

			if (ret <= 0) {
				free(*OUTPUT);
				*OUTPUT = NULL;
			}

			return (ret == REGEXP_MATCH);
		}

		struct regexp *compile(const char *pattern) {
			char *esc_regexp = escape_chars(pattern, strlen(pattern));
			struct regexp *ret = $self->compile(esc_regexp);
			free(esc_regexp);
			return ret;
		}
	}
};
