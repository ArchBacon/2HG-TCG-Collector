<?php

namespace App\Games\MTG\Enum;

enum ImageStatus: string
{
    case Missing = 'missing';
    case Placeholder = 'placeholder';
    case Lowres = 'lowres';
    case HighresScan = 'highres_scan';
}
