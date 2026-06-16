# name: discourse-localized-groups
# about: Multi-language localization support for Discourse Group display names
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/canbekcan/discourse-localized-groups

# frozen_string_literal: true

enabled_site_setting :localized_groups_enabled

after_initialize do
  next unless SiteSetting.localized_groups_enabled

  reloadable_patch do
    # ====================================================================
    # 1. MODEL YAMASI: Backend işlemleri, E-postalar ve Flair unvanları için
    # ====================================================================
    module ::LocalizedGroupModelPatch
      def display_name
        raw_display_name = read_attribute(:display_name)
        
        # Kontrol 1: Veritabanındaki display_name doğrudan 'groups.' çeviri anahtarı içeriyorsa
        if raw_display_name.to_s.start_with?('groups.')
          return I18n.t(raw_display_name)
        end

        # Kontrol 2: Grubun sistem adına göre otomatik eşleşme (groups.grup_adi.display_name)
        dynamic_key = "groups.#{name}.display_name"
        if I18n.exists?(dynamic_key)
          return I18n.t(dynamic_key)
        end

        # Hiçbir çeviri anahtarı bulunamazsa orijinal çekirdek metoduna pasla
        super
      end
    end

    require_dependency 'group'
    class ::Group
      prepend ::LocalizedGroupModelPatch
    end

    # ====================================================================
    # 2. SERIALIZER YAMASI: Frontend (EmberJS Payload API) JSON çıktıları için
    # ====================================================================
    module ::LocalizedBasicGroupSerializerPatch
      def display_name
        # Model yaması çoğu durumu kurtarır fakat serileştirme anındaki
        # önbellek (cache) yapılarını güvenceye almak için serializer katmanını da mühürlüyoruz.
        if object.display_name.to_s.start_with?('groups.')
          return I18n.t(object.display_name)
        end

        dynamic_key = "groups.#{object.name}.display_name"
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