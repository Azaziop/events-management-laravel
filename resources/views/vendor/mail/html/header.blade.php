@props(['url'])
<tr>
<td class="header">
<a href="{{ $url }}" style="display: inline-block;">
@if (trim($slot) === 'Laravel' || trim($slot) === 'EventApp')
<table cellpadding="0" cellspacing="0" border="0" style="margin: 0 auto;">
    <tr>
        <td style="vertical-align: middle; padding-right: 12px;">
            <div style="width: 48px; height: 48px; background-color: #dbeafe; border-radius: 50%; text-align: center; line-height: 48px;">
                <svg width="32" height="32" style="vertical-align: middle;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="#3b82f6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
                </svg>
            </div>
        </td>
        <td style="vertical-align: middle;">
            <span style="font-size: 28px; font-weight: bold; color: #3b82f6; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">EventApp</span>
        </td>
    </tr>
</table>
@else
{!! $slot !!}
@endif
</a>
</td>
</tr>
