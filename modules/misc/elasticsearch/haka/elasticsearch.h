/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef _ELASTICSEARCH_H_
#define _ELASTICSEARCH_H_

#define BASE64_ENCODE_LEN(len) ((len * 4) / 3 + 1)
#define ALERT_PREFIX_LENGTH  BASE64_ENCODE_LEN(16)

#include <haka/types.h>

#include "json.h"


struct elasticsearch_connector;

struct elasticsearch_connector *elasticsearch_connector_new(const char *server);
bool                            elasticsearch_connector_close(struct elasticsearch_connector *connector);
void                            elasticsearch_genid(char *);
bool                            elasticsearch_newindex(struct elasticsearch_connector *connector,
		const char *index, json_t *data);
bool                            elasticsearch_insert(struct elasticsearch_connector *connector,
		const char *index, const char *type, const char *id, json_t *doc);
bool                            elasticsearch_update(struct elasticsearch_connector *connector,
		const char *index, const char *type, const char *id, json_t *doc);

#endif /* _ELASTICSEARCH_H_ */
