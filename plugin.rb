# name: discourse-localized-groups
# about: Multi-language localization support for Discourse Group full names and bios
# version: 1.0.2
# authors: Can Bekcan
# url: https://github.com/canbekcan/discourse-localized-groups

# frozen_string_literal: true

enabled_site_setting :localized_groups_enabled

after_initialize do
  next unless SiteSetting.localized_groups_enabled

  reloadable_patch do
    # ====================================================================
    # 1. MODEL YAMASI: Backend işlemleri ve E-postalar için (full_name)
    # ====================================================================
    module ::LocalizedGroupModelPatch
      def full_name
        raw_full_name = read_attribute(:full_name)
        
        if raw_full_name.to_s.start_with?('groups.')
          return I18n.t(raw_full_name)
        end

        dynamic_key = "groups.#{name}.full_name"
        if I18n.exists?(dynamic_key)
          return I18n.t(dynamic_key)
        end

        super
      end
    end

    require_dependency 'group'
    class ::Group
      prepend ::LocalizedGroupModelPatch
    end

    # ====================================================================
    # 2. BASIC SERIALIZER YAMASI: Frontend listeleri ve kartlar için
    # ====================================================================
    module ::LocalizedBasicGroupSerializerPatch
      def full_name
        if object.full_name.to_s.start_with?('groups.')
          return I18n.t(object.full_name)
        end

        dynamic_key = "groups.#{object.name}.full_name"
        if I18n.exists?(dynamic_key)
          return I18n.t(dynamic_key)
        end

        super
      end
    end

    require_dependency 'basic_group_serializer'
    class ::BasicGroupSerializer
      prepend ::LocalizedBasicGroupSerializerPatch
    end

    # ====================================================================
    # 3. GROUP SERIALIZER YAMASI: Grup Detay Sayfası (Bio/Hakkında) için
    # ====================================================================
    module ::LocalizedGroupSerializerPatch
      def bio_cooked
        dynamic_key = "groups.#{object.name}.bio"
        if I18n.exists?(dynamic_key)
          # YAML dosyasından gelen metni Discourse Markdown motorundan (PrettyText) geçiriyoruz.
          # Bu sayede YAML içinde **kalın** veya [link](url) gibi Markdown kullanabilirsiniz.
          return PrettyText.cook(I18n.t(dynamic_key))
        end

        super
      end

      def bio_excerpt
        dynamic_key = "groups.#{object.name}.bio"
        if I18n.exists?(dynamic_key)
          # Arama sonuçları vb. yerler için HTML taglerinden arındırılmış 300 karakterlik özet
          return PrettyText.excerpt(PrettyText.cook(I18n.t(dynamic_key)), 300)
        end

        super
      end
    end

    require_dependency 'group_serializer'
    class ::GroupSerializer
      prepend ::LocalizedGroupSerializerPatch
    end
  end
end