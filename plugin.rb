# name: discourse-localized-groups
# about: Multi-language localization support for Discourse Group full names and bios
# version: 1.0.3
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
    # 2. BASIC SERIALIZER YAMASI: Frontend listeleri, grup detayları ve bio
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

      # Grup sayfası 'Hakkında' metni
      def bio_cooked
        dynamic_key = "groups.#{object.name}.bio"
        if I18n.exists?(dynamic_key)
          # YAML dosyasından gelen metni Discourse Markdown motorundan (PrettyText) geçiriyoruz.
          return PrettyText.cook(I18n.t(dynamic_key))
        end

        super
      end

      # Kartlarda veya aramalarda çıkan 300 karakterlik özet
      def bio_excerpt
        dynamic_key = "groups.#{object.name}.bio"
        if I18n.exists?(dynamic_key)
          return PrettyText.excerpt(PrettyText.cook(I18n.t(dynamic_key)), 300)
        end

        super
      end
    end

    # Hem Görünen Ad (full_name) hem de Hakkında (bio) tek bir çekirdek dosyada yamalanıyor
    require_dependency 'basic_group_serializer'
    class ::BasicGroupSerializer
      prepend ::LocalizedBasicGroupSerializerPatch
    end
  end
end