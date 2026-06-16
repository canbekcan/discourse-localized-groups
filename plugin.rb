# name: discourse-localized-groups
# about: Multi-language localization support for Discourse Group full names
# version: 1.0.1
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
        
        # Kontrol 1: Admin panelden manuel olarak 'groups.' prefixi girilmişse
        if raw_full_name.to_s.start_with?('groups.')
          return I18n.t(raw_full_name)
        end

        # Kontrol 2: Grubun sistem adına (slug) göre otomatik locale eşleşmesi
        dynamic_key = "groups.#{name}.full_name"
        if I18n.exists?(dynamic_key)
          return I18n.t(dynamic_key)
        end

        # Bulunamazsa Discourse'un orijinal metot/kolon verisini döndür
        super
      end
    end

    require_dependency 'group'
    class ::Group
      prepend ::LocalizedGroupModelPatch
    end

    # ====================================================================
    # 2. SERIALIZER YAMASI: Frontend (EmberJS) API JSON çıktıları için
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
  end
end