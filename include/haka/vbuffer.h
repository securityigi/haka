
#ifndef _HAKA_VBUFFER_H
#define _HAKA_VBUFFER_H

#include <haka/types.h>
#include <haka/container/list.h>
#include <haka/lua/object.h>


/*
 * Buffer
 */

#define ALL   (size_t)-1

struct vbuffer_iterator;
struct vbuffer_data;
struct vsubbuffer;

struct vbuffer_data_ops {
	void   (*addref)(struct vbuffer_data *data);
	void   (*release)(struct vbuffer_data *data);
	uint8 *(*get)(struct vbuffer_data *data, bool write);
};

struct vbuffer_data {
	struct vbuffer_data_ops  *ops;
};

struct vbuffer_flags {
	bool                    modified:1;
	bool                    writable:1;
};

struct vbuffer {
	struct lua_object        lua_object;
	struct vbuffer          *next;
	size_t                   length;
	size_t                   offset;
	struct vbuffer_data     *data;
	struct vbuffer_flags     flags;
	struct vbuffer_iterator *iterators;
};


struct vbuffer *vbuffer_create_new(size_t size);
struct vbuffer *vbuffer_create_from(struct vbuffer_data *data, size_t length);
struct vbuffer *vbuffer_extract(struct vbuffer *buf, size_t offset, size_t length, bool mark_modified);
void            vbuffer_setmode(struct vbuffer *buf, bool readonly);
void            vbuffer_free(struct vbuffer *buf);
bool            vbuffer_insert(struct vbuffer *buf, size_t offset, struct vbuffer *data, bool mark_modified);
bool            vbuffer_erase(struct vbuffer *buf, size_t offset, size_t len);
bool            vbuffer_flatten(struct vbuffer *buf);
bool            vbuffer_compact(struct vbuffer *buf);
bool            vbuffer_isflat(struct vbuffer *buf);
size_t          vbuffer_size(struct vbuffer *buf);
bool            vbuffer_checksize(struct vbuffer *buf, size_t minsize);
uint8          *vbuffer_mmap(struct vbuffer *buf, void **iter, size_t *len, bool write);
uint8           vbuffer_getbyte(struct vbuffer *buf, size_t offset);
void            vbuffer_setbyte(struct vbuffer *buf, size_t offset, uint8 byte);
bool            vbuffer_ismodified(struct vbuffer *buf);
void            vbuffer_clearmodified(struct vbuffer *buf);
bool            vbuffer_zero(struct vbuffer *buf, bool mark_modified);


/*
 * Iterator
 */

struct vbuffer_iterator {
	struct list     list;
	struct vbuffer *buffer;
	size_t          offset;
	bool            post:1;
	bool            readonly:1;
	bool            registered:1;
};

bool            vbuffer_iterator(struct vbuffer *buf, struct vbuffer_iterator *iter, bool post, bool readonly);
bool            vbuffer_iterator_copy(const struct vbuffer_iterator *src, struct vbuffer_iterator *dst);
bool            vbuffer_iterator_register(struct vbuffer_iterator *iter);
bool            vbuffer_iterator_unregister(struct vbuffer_iterator *iter);
bool            vbuffer_iterator_clear(struct vbuffer_iterator *iter);
bool            vbuffer_iterator_sub(struct vbuffer_iterator *iter, struct vsubbuffer *buffer, size_t len, bool advance);
size_t          vbuffer_iterator_read(struct vbuffer_iterator *iter, uint8 *buffer, size_t len, bool advance);
size_t          vbuffer_iterator_write(struct vbuffer_iterator *iter, uint8 *buffer, size_t len, bool advance);
bool            vbuffer_iterator_insert(struct vbuffer_iterator *iter, struct vbuffer *data);
bool            vbuffer_iterator_erase(struct vbuffer_iterator *iter, size_t len);
size_t          vbuffer_iterator_advance(struct vbuffer_iterator *iter, size_t len);


/*
 * Sub buffer
 */

struct vsubbuffer {
	struct vbuffer_iterator  position;
	size_t                   length;
};

bool            vbuffer_sub(struct vbuffer *buf, size_t offset, size_t length, struct vsubbuffer *sub);
bool            vsubbuffer_sub(struct vsubbuffer *buf, size_t offset, size_t length, struct vsubbuffer *sub);
bool            vsubbuffer_isflat(struct vsubbuffer *buf);
bool            vsubbuffer_flatten(struct vsubbuffer *buf);
size_t          vsubbuffer_size(struct vsubbuffer *buf);
uint8          *vsubbuffer_mmap(struct vsubbuffer *buf, void **iter, size_t *remlen, size_t *len, bool write);
int64           vsubbuffer_asnumber(struct vsubbuffer *buf, bool bigendian);
void            vsubbuffer_setnumber(struct vsubbuffer *buf, bool bigendian, int64 num);
int64           vsubbuffer_asbits(struct vsubbuffer *buf, size_t offset, size_t bits, bool bigendian);
void            vsubbuffer_setbits(struct vsubbuffer *buf, size_t offset, size_t bits, bool bigendian, int64 num);
size_t          vsubbuffer_asstring(struct vsubbuffer *buf, char *str, size_t len);
size_t          vsubbuffer_setfixedstring(struct vsubbuffer *buf, const char *str, size_t len);
void            vsubbuffer_setstring(struct vsubbuffer *buf, const char *str, size_t len);
uint8           vsubbuffer_getbyte(struct vsubbuffer *buf, size_t offset);
void            vsubbuffer_setbyte(struct vsubbuffer *buf, size_t offset, uint8 byte);


/*
 * Buffer views
 */
/*
enum vbuffer_view_option {
	EBUFFERVIEW_BIGENDIAN,
	EBUFFERVIEW_LITTLEENDIAN,
};

enum vbuffer_view_type {
	EBUFFERVIEW_NULL        =  0,
	EBUFFERVIEW_INT8        = -1,
	EBUFFERVIEW_UINT8       =  1,
	EBUFFERVIEW_INT16       = -2,
	EBUFFERVIEW_UINT16      =  2,
	EBUFFERVIEW_INT32       = -4,
	EBUFFERVIEW_UINT32      =  4,
	EBUFFERVIEW_INT64       = -8,
	EBUFFERVIEW_UINT64      =  8,
	EBUFFERVIEW_FIXEDSTRING =  256,
	EBUFFERVIEW_STRING,
};

#define VBUFFER_VIEW_NUMBER(type) \
	struct vbuffer_view_number_##type; \
	\
	struct vbuffer_view_number_##type##_ops { \
		type     (*get)(struct vbuffer_view_number_##type *view); \
		void     (*set)(struct vbuffer_view_number_##type *view, type num); \
	}; \
	\
	struct vbuffer_view_number_##type { \
		struct vbuffer_view_##type##_ops   *ops; \
		struct vbuffer                     *buffer; \
		size_t                              offset; \
	};

VBUFFER_VIEW_NUMBER(int8);
VBUFFER_VIEW_NUMBER(uint8);
VBUFFER_VIEW_NUMBER(int16);
VBUFFER_VIEW_NUMBER(uint16);
VBUFFER_VIEW_NUMBER(int32);
VBUFFER_VIEW_NUMBER(uint32);

struct vbuffer_view_fixedstring;

struct vbuffer_view_fixedstring_ops {
	size_t   (*get)(struct vbuffer_view_fixedstring *view, char *str, size_t len);
	char    *(*get_direct)(struct vbuffer_view_fixedstring *view, size_t *len);
	size_t   (*set)(struct vbuffer_view_fixedstring *view, const char *str, size_t len);
};

struct vbuffer_view_fixedstring {
	struct vbuffer_view_fixedstring_ops   *ops;
	struct vbuffer                        *buffer;
	size_t                                 offset;
	size_t                                 length;
};

struct vbuffer_view_string;

struct vbuffer_view_string_ops {
	size_t      (*get)(struct vbuffer_view_string *view, char *str, size_t len);
	const char *(*get_direct)(struct vbuffer_view_string *view, size_t *len);
	bool        (*set)(struct vbuffer_view_string *view, const char *str, size_t len);
	bool        (*set_direct)(struct vbuffer_view_string *view, char *str, size_t len);
};

struct vbuffer_view_string {
	struct vbuffer_view_string_ops   *ops;
	struct vsubbuffer                 buffer;
	char                             *modifs;
	size_t                            modiflen;
};

struct vbuffer_view {
	enum vbuffer_view_type                 type;
	union {
		struct vbuffer_view_number_int8    int8_view;
		struct vbuffer_view_number_uint8   uint8_view;
		struct vbuffer_view_number_int16   int16_view;
		struct vbuffer_view_number_uint16  uint16_view;
		struct vbuffer_view_number_int32   int32_view;
		struct vbuffer_view_number_uint32  uint32_view;
		struct vbuffer_view_fixedstring    fixedstring_view;
		struct vbuffer_view_string         string_view;
	};
};

bool            vsubbuffer_view_create(struct vbuffer_view *view, struct vsubbuffer *buf,
		enum vbuffer_view_type type, enum vbuffer_view_option options);
*/
#endif /* _HAKA_VBUFFER_H */
