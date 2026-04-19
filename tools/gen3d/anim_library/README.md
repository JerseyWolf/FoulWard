# Mixamo FBX animation library

Place downloaded **Mixamo** FBX clips here so `pipeline/stage4_anim.py` can merge them in Blender.

Required filenames (see `ANIM_NAME_MAP` in `pipeline/stage4_anim.py`):

- `Idle.fbx`
- `Walking.fbx`
- `Running.fbx`
- `Punching.fbx`
- `Sword And Shield Slash.fbx`
- `Receiving Damage.fbx`
- `Dying.fbx`
- `Falling Back Death.fbx`
- `Getting Up.fbx`

Bulk download options: browser helper scripts such as [gnuton/mixamo_anims_downloader](https://github.com/gnuton/mixamo_anims_downloader) (log in to Mixamo in browser; respect Adobe ToS).

Rigging must use the **same skeleton** as your uploaded character so retargeting in Blender is consistent.
