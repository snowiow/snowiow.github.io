SHELL       := /bin/bash
OUTPUT       = docs
CONTENT_DIR  = content/
POSTS_DIR    = content/posts
INFO_DIR	 = content/info
TEMPLATE_DIR = content/templates
POSTS        = $(shell find $(POSTS_DIR) -name '*.md' -printf '%f\n' | sed -E 's/(.*)\.md/$(OUTPUT)\/posts\/\1.html/g')
INFO_PAGES   = $(shell find $(INFO_DIR) -name '*.md' -printf '%f\n' | sed -E 's/(.*)\.md/$(OUTPUT)\/\1.html/g')
CSS_FILES    = $(shell ls content/css/*.css)
IMAGES       = $(shell find content/images -name '*.*' -printf '$(OUTPUT)/images/%f\n')
META_FILES   = $(shell find content/metadata -name '*' -printf '$(OUTPUT)/%f\n' | tail +2)
TARGET_CSS   = $(OUTPUT)/css/style.css

build: directories webfonts $(TARGET_CSS) $(IMAGES) $(POSTS) $(INFO_PAGES) $(OUTPUT)/index.html $(OUTPUT)/archive.html $(META_FILES)

directories: $(OUTPUT)/webfonts $(OUTPUT)/css $(OUTPUT)/images $(OUTPUT)/posts

$(OUTPUT)/webfonts $(OUTPUT)/images $(OUTPUT)/css $(OUTPUT)/posts:
	@mkdir -p $@

$(OUTPUT)/images/%: content/images/%
	@cp $< $@

webfonts:
	@cp content/webfonts/*.woff* $(OUTPUT)/webfonts/

$(TARGET_CSS): $(CSS_FILES)
	@cat $(CSS_FILES) > $@

$(OUTPUT)/posts/%.html: $(POSTS_DIR)/%.md
	@pandoc \
		--standalone \
		--css=../css/style.css \
		--highlight-style=pygments \
		--include-before-body=$(TEMPLATE_DIR)/header.html \
		--include-after-body=$(TEMPLATE_DIR)/footer.html \
		--template=$(TEMPLATE_DIR)/post.html \
		-i $< -o $@

$(OUTPUT)/%.html: $(INFO_DIR)/%.md
	@pandoc \
		--standalone \
		--css=css/style.css \
		--highlight-style=pygments \
		--include-before-body=$(TEMPLATE_DIR)/header.html \
		--include-after-body=$(TEMPLATE_DIR)/footer.html \
		--template=$(TEMPLATE_DIR)/default.html \
		-i $< -o $@

$(OUTPUT)/index.html: $(OUTPUT)/index_metadata.yml
	@pandoc \
		--standalone \
		--css=css/style.css \
		--include-before-body=$(TEMPLATE_DIR)/header.html \
		--include-after-body=$(TEMPLATE_DIR)/footer.html \
		--template=$(TEMPLATE_DIR)/index.html \
		--metadata-file=$< \
		-o $@ -i content/index.md && rm $<

$(OUTPUT)/index_metadata.yml: $(CONTENT_DIR)/index.md
	@./gen-listing-meta.sh $@ 10 $(POSTS_DIR)/*.md

$(OUTPUT)/archive.html: $(OUTPUT)/archive_metadata.yml
	@pandoc \
		--standalone \
		--css=css/style.css \
		--include-before-body=$(TEMPLATE_DIR)/header.html \
		--include-after-body=$(TEMPLATE_DIR)/footer.html \
		--template=$(TEMPLATE_DIR)/archive.html \
		--metadata-file=$< \
		-o $@ -i content/archive.md && rm $<

$(OUTPUT)/archive_metadata.yml: $(CONTENT_DIR)/archive.md
	@./gen-listing-meta.sh $@ 1000 $(POSTS_DIR)/*.md

$(OUTPUT)/%: content/metadata/%
	@cp $< $@

clean:
	@rm -r $(OUTPUT)/*

serve:
	@docker start snow-dev.com &> /dev/null || \
		docker run --name snow-dev.com \
		-v $$(pwd)/$(OUTPUT):/usr/share/nginx/html:ro \
		-p 8088:80 \
		-d nginx
	@echo "server started at localhost:8088"
