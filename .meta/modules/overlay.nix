final: prev:
  {
    tmuxPlugins = prev.tmuxPlugins // {
      resurrect = (prev.tmuxPlugins.resurrect.overrideAttrs (oldAttrs: {
        version = "unstable-2023-03-06";
        src = prev.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-resurrect";
          rev = "cff343cf9e81983d3da0c8562b01616f12e8d548";
          sha256 = "0djfz7m4l8v2ccn1a97cgss5iljhx9k2p8k9z50wsp534mis7i0m";
        };
      }));
      tmux-volume = (prev.tmuxPlugins.mkTmuxPlugin {
        pluginName = "volume";
        version = "unstable-2018-10-02";
        src = prev.fetchFromGitHub {
          owner = "levex";
          repo = "tmux-plugin-volume";
          rev = "4e4032d2fc3283e031334467cd3a4fd0abe73078";
          sha256 = "0big068pj6xl9s1l1bwjmy0d29pv9v93v55cn459mhhz82xv90y7";
        };
      });
      tmux-suspend = (prev.tmuxPlugins.mkTmuxPlugin {
        pluginName = "suspend";
        version = "unstable-2023-01-15";
        src = prev.fetchFromGitHub {
          owner = "MunifTanjim";
          repo = "tmux-suspend";
          rev = "1a2f806666e0bfed37535372279fa00d27d50d14";
          sha256 = "0j7vjrwc7gniwkv1076q3wc8ccwj42zph5wdmsm9ibz6029wlmzv";
        };
      });
    };

    fishPlugins = prev.fishPlugins // {
      fish-abbreviation-tips = prev.fetchFromGitHub {
        name = "fish-abbreviation-tips";
        owner = "gazorby";
        repo = "fish-abbreviation-tips";
        rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
        sha256 = "05b5qp7yly7mwsqykjlb79gl24bs6mbqzaj5b3xfn3v2b7apqnqp";
      };
      autopair-fish = prev.fetchFromGitHub {
        name = "autopair-fish";
        owner = "jorgebucaran";
        repo = "autopair.fish";
        rev = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
        sha256 = "0l2g922gwjd64ar41j7cp09vvvrs30ha55b85nidni4i4bbfvpda";
      };
      async-prompt = prev.fetchFromGitHub {
        name = "async-prompt";
        owner = "acomagu";
        repo = "fish-async-prompt";
        rev = "4c732cc043b8dd04e64a169ec6bbf3a9b394819f";
        sha256 = "1f7l93xs2bn500p85i4jg7iczmyhh66ixc2shslp5qlqv4h9j2k2";
      };
    };
  }
